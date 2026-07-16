"""Configuración de la aplicación, cargada desde variables de entorno / .env.

Fuente única de verdad para settings. No leer os.environ directamente en otros
módulos: importar `settings` de aquí. Ver docs/06_Backend.md y docs/09_Seguridad.md.
"""

from functools import lru_cache
from typing import Literal

from pydantic_settings import BaseSettings, SettingsConfigDict

Environment = Literal["local", "test", "staging", "production"]


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # ── Entorno ──────────────────────────────────────────────
    app_env: Environment = "local"
    debug: bool = False

    # ── Base de datos ────────────────────────────────────────
    # La APP se conecta con un rol NO superusuario para que RLS aplique de verdad.
    database_url: str = "postgresql+asyncpg://agora_app:agora_app@localhost:5432/agora"
    # Las MIGRACIONES se ejecutan con el rol dueño (crea/altera tablas). Si no se
    # define, se usa database_url.
    migration_database_url: str | None = None

    # ── Seguridad / JWT ──────────────────────────────────────
    jwt_secret: str = "CHANGE_ME"
    jwt_algorithm: str = "HS256"
    access_token_ttl_minutes: int = 15
    refresh_token_ttl_days: int = 30

    # ── CORS ─────────────────────────────────────────────────
    cors_origins: str = "http://localhost:5173"

    @property
    def cors_origins_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    """Devuelve la instancia única de Settings (cacheada)."""
    return Settings()


settings = get_settings()
