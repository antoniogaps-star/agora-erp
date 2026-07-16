"""Validación de configuración (no requiere base de datos)."""

import pytest

from app.core.config import Settings


def test_secret_debil_rechazado_en_produccion(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("APP_ENV", "production")
    monkeypatch.setenv("JWT_SECRET", "CHANGE_ME")
    with pytest.raises(ValueError, match="JWT_SECRET"):
        Settings(_env_file=None)  # type: ignore[call-arg]


def test_secret_corto_rechazado_en_produccion(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("APP_ENV", "production")
    monkeypatch.setenv("JWT_SECRET", "corta")
    with pytest.raises(ValueError, match="JWT_SECRET"):
        Settings(_env_file=None)  # type: ignore[call-arg]


def test_secret_fuerte_aceptado_en_produccion(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("APP_ENV", "production")
    monkeypatch.setenv("JWT_SECRET", "x" * 40)
    settings = Settings(_env_file=None)  # type: ignore[call-arg]
    assert settings.app_env == "production"


def test_secret_debil_permitido_en_local(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("APP_ENV", "local")
    monkeypatch.setenv("JWT_SECRET", "CHANGE_ME")
    settings = Settings(_env_file=None)  # type: ignore[call-arg]
    assert settings.app_env == "local"
