"""Normalización de la respuesta de IA (sin red)."""

from app.modules.products.voice_ai import _shape


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
