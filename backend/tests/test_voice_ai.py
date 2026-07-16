"""Parseo de la respuesta de Gemini (sin red)."""

from app.modules.products.voice_ai import _extract


def test_extract_respuesta_gemini() -> None:
    data = {
        "candidates": [
            {
                "content": {
                    "parts": [
                        {"text": '{"name":"Corona media","pieces":120,"note":"5 x 24"}'}
                    ]
                }
            }
        ]
    }
    result = _extract(data)
    assert result["name"] == "Corona media"
    assert result["pieces"] == 120
    assert result["note"] == "5 x 24"


def test_extract_normaliza_tipos() -> None:
    data = {
        "candidates": [
            {"content": {"parts": [{"text": '{"name":"  Agua  ","pieces":"50"}'}]}}
        ]
    }
    result = _extract(data)
    assert result["name"] == "Agua"
    assert result["pieces"] == 50
    assert result["note"] is None
