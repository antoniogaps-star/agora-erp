"""Interpretación de dictado de inventario con IA (Google Gemini, capa gratuita).

Convierte habla libre en español a {name, pieces}. Entiende nombres reales con
palabras raras ("Corona media", "Modelo lata") y presentaciones (caja, six, docena).
Si no hay llave configurada, lanza 503 y el móvil recurre a sus reglas locales.
"""

import json
from typing import Any

import httpx

from app.core.config import settings
from app.shared.errors import api_error

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


def _extract(data: dict[str, Any]) -> dict[str, Any]:
    text = data["candidates"][0]["content"]["parts"][0]["text"]
    parsed = json.loads(text)
    return {
        "name": str(parsed.get("name", "")).strip(),
        "pieces": int(parsed.get("pieces", 0) or 0),
        "note": parsed.get("note"),
    }


async def parse_product(transcript: str) -> dict[str, Any]:
    if not settings.gemini_api_key:
        raise api_error(503, "AI_NOT_CONFIGURED", "IA de dictado no configurada")

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
        # Se incluye el detalle de Google para poder diagnosticar (llave, modelo, cuota).
        detail = resp.text[:250].replace("\n", " ")
        raise api_error(502, "AI_ERROR", f"Gemini {resp.status_code}: {detail}")

    try:
        return _extract(resp.json())
    except (KeyError, IndexError, ValueError) as exc:
        raise api_error(502, "AI_BAD_RESPONSE", "Respuesta de IA no interpretable") from exc
