"""Normalización de la respuesta de IA y cascada de proveedores (sin red)."""

from typing import Any

import pytest
from fastapi import HTTPException

from app.modules.products import voice_ai
from app.modules.products.voice_ai import _shape, parse_product


def test_shape_normaliza_tipos() -> None:
    result = _shape({"name": "  Corona media  ", "pieces": "120", "note": "5 x 24"})
    assert result["name"] == "Corona media"
    assert result["pieces"] == 120
    assert result["note"] == "5 x 24"


def test_shape_valores_faltantes() -> None:
    result = _shape({"name": "Agua"})
    assert result["name"] == "Agua"
    assert result["pieces"] == 0
    assert result["note"] is None


def _fake_keys(monkeypatch: pytest.MonkeyPatch, *, groq: str = "", gemini: str = "") -> None:
    monkeypatch.setattr(voice_ai.settings, "groq_api_key", groq)
    monkeypatch.setattr(voice_ai.settings, "gemini_api_key", gemini)


async def _ok(_: str) -> dict[str, Any]:
    return {"name": "Corona media", "pieces": 120, "note": "5 x 24"}


async def _cuota_agotada(_: str) -> dict[str, Any]:
    raise HTTPException(status_code=502, detail={"code": "AI_ERROR", "message": "Groq 429"})


@pytest.mark.anyio
async def test_sin_llaves_responde_503(monkeypatch: pytest.MonkeyPatch) -> None:
    _fake_keys(monkeypatch)
    with pytest.raises(HTTPException) as exc:
        await parse_product("corona media 5 cajas")
    assert exc.value.status_code == 503
    assert exc.value.detail["code"] == "AI_NOT_CONFIGURED"


@pytest.mark.anyio
async def test_groq_falla_y_cae_a_gemini(monkeypatch: pytest.MonkeyPatch) -> None:
    _fake_keys(monkeypatch, groq="k1", gemini="k2")
    monkeypatch.setattr(voice_ai, "_call_groq", _cuota_agotada)
    monkeypatch.setattr(voice_ai, "_call_gemini", _ok)
    assert (await parse_product("corona media 5 cajas"))["pieces"] == 120


@pytest.mark.anyio
async def test_si_fallan_todos_propaga_el_ultimo_error(monkeypatch: pytest.MonkeyPatch) -> None:
    _fake_keys(monkeypatch, groq="k1", gemini="k2")
    monkeypatch.setattr(voice_ai, "_call_groq", _cuota_agotada)
    monkeypatch.setattr(voice_ai, "_call_gemini", _cuota_agotada)
    with pytest.raises(HTTPException) as exc:
        await parse_product("corona media 5 cajas")
    assert exc.value.status_code == 502
