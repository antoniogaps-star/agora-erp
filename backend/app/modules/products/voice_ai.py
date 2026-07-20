"""Interpretación de dictado de inventario con IA (capa gratuita).

Convierte habla libre en español a {name, pieces}. Entiende nombres reales con
palabras raras ("Corona media", "Modelo lata") y presentaciones (caja, six, docena).

Proveedores en cascada: primero Groq (cupo gratuito amplio), luego Google Gemini.
Se salta el que no tenga llave, y si uno falla (cuota agotada, red, respuesta rara)
se intenta el siguiente. Sin ninguna llave usable, lanza 503 y el móvil recurre a
sus reglas locales.
"""

import json
import logging
from collections.abc import Awaitable, Callable
from typing import Any

import httpx
from fastapi import HTTPException

from app.core.config import settings
from app.shared.errors import api_error

logger = logging.getLogger(__name__)

_SYSTEM = """Eres un asistente de captura de inventario para una tienda mexicana.
El usuario DICTA un producto y su cantidad de llegada. Devuelve SOLO un JSON con:
  name  (string): el nombre del producto, capitalizado (ej. "Corona media").
  pieces (entero): el TOTAL de piezas individuales.
  note  (string): breve explicación del cálculo (ej. "20 cajas x 24").

Reglas de presentaciones (multiplica cantidad x tamaño):
- pieza, lata, botella, unidad, caguama = 1 pieza.
- six, sixpack = 6 ; media docena = 6 ; docena = 12.
- caja, cartón, paquete: si dicen "de N" usa N; si NO lo dicen, para cerveza,
  refresco o agua asume 24; para cigarros asume 20; en otro caso asume 12.
- Si el usuario NO menciona cantidad ni presentación, pieces = 0.

Ejemplos:
"corona media 5 cajas de 24"      -> {"name":"Corona media","pieces":120,"note":"5 x 24"}
"modelo lata 20 cajas"            -> {"name":"Modelo lata","pieces":480,"note":"20 x 24"}
"cerveza corona mega 50 cajas"    -> {"name":"Corona mega","pieces":1200,"note":"50 x 24"}
"sabritas 40 piezas"              -> {"name":"Sabritas","pieces":40,"note":"40 piezas"}
"marlboro 10 cajas"               -> {"name":"Marlboro","pieces":200,"note":"10 x 20 (cigarros)"}
"jugo del valle"                  -> {"name":"Jugo del valle","pieces":0,"note":"sin cantidad"}
Responde únicamente el JSON, sin texto adicional."""


def _shape(parsed: dict[str, Any]) -> dict[str, Any]:
    return {
        "name": str(parsed.get("name", "")).strip(),
        "pieces": int(parsed.get("pieces", 0) or 0),
        "note": parsed.get("note"),
    }


async def _call_groq(transcript: str) -> dict[str, Any]:
    body = {
        "model": settings.groq_model,
        "messages": [
            {"role": "system", "content": _SYSTEM},
            {"role": "user", "content": transcript},
        ],
        "response_format": {"type": "json_object"},
        "temperature": 0,
    }
    headers = {"Authorization": f"Bearer {settings.groq_api_key}"}
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            resp = await client.post(
                "https://api.groq.com/openai/v1/chat/completions", json=body, headers=headers
            )
    except httpx.HTTPError as exc:
        raise api_error(502, "AI_UNREACHABLE", "No se pudo contactar la IA") from exc
    if resp.status_code != 200:
        raise api_error(502, "AI_ERROR", f"Groq {resp.status_code}: {resp.text[:250]}")
    text = resp.json()["choices"][0]["message"]["content"]
    return _shape(json.loads(text))


async def _call_gemini(transcript: str) -> dict[str, Any]:
    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        f"{settings.gemini_model}:generateContent"
    )
    body = {
        "system_instruction": {"parts": [{"text": _SYSTEM}]},
        "contents": [{"parts": [{"text": transcript}]}],
        "generationConfig": {"responseMimeType": "application/json", "temperature": 0},
    }
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            resp = await client.post(url, params={"key": settings.gemini_api_key}, json=body)
    except httpx.HTTPError as exc:
        raise api_error(502, "AI_UNREACHABLE", "No se pudo contactar la IA") from exc
    if resp.status_code != 200:
        detail = resp.text[:250].replace("\n", " ")
        raise api_error(502, "AI_ERROR", f"Gemini {resp.status_code}: {detail}")
    text = resp.json()["candidates"][0]["content"]["parts"][0]["text"]
    return _shape(json.loads(text))


async def parse_product(transcript: str) -> dict[str, Any]:
    """Intenta cada proveedor configurado en orden; devuelve el primero que responda.

    Si un proveedor falla (429 por cuota, red caída, JSON ilegible) se registra y se
    pasa al siguiente, para que quedarse sin cupo en uno no tumbe el dictado.
    """
    providers: list[tuple[str, Callable[[str], Awaitable[dict[str, Any]]]]] = []
    if settings.groq_api_key:
        providers.append(("Groq", _call_groq))
    if settings.gemini_api_key:
        providers.append(("Gemini", _call_gemini))
    if not providers:
        raise api_error(503, "AI_NOT_CONFIGURED", "IA de dictado no configurada")

    last_error: HTTPException | None = None
    for name, call in providers:
        try:
            return await call(transcript)
        except HTTPException as exc:
            last_error = exc
        except (KeyError, IndexError, ValueError) as exc:
            last_error = api_error(502, "AI_BAD_RESPONSE", "Respuesta de IA no interpretable")
            last_error.__cause__ = exc
        logger.warning("Proveedor de IA %s falló: %s", name, last_error.detail)

    assert last_error is not None  # providers no está vacío, el bucle siempre lo asigna
    raise last_error
