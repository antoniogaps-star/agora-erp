"""Configuración de la aplicación, cargada desde variables de entorno / .env.

Fuente única de verdad para settings. No leer os.environ directamente en otros
módulos: importar `settings` de aquí. Ver docs/06_Backend.md y docs/09_Seguridad.md.
"""

from functools import lru_cache
from typing import Literal

from pydantic import field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

Environment = Literal["local", "test", "staging", "production"]

# Valores de ejemplo/débiles que NUNCA deben usarse en entornos reales.
_WEAK_SECRETS = {
    "CHANGE_ME",
    "CHANGE_ME_use_a_strong_random_secret",
    "ci-test-secret",
}
_MIN_SECRET_LENGTH = 32


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

    @field_validator("database_url", "migration_database_url", mode="before")
    @classmethod
    def _normalize_pg_scheme(cls, value: str | None) -> str | None:
        """Acepta URLs de Postgres de cualquier proveedor (Railway, Render, Heroku…).

        Los proveedores entregan `postgres://` o `postgresql://`; SQLAlchemy async
        necesita `postgresql+asyncpg://`. Se normaliza aquí para poder pegar la
        variable del proveedor tal cual.
        """
        if value is None:
            return value
        for prefix in ("postgres://", "postgresql://"):
            if value.startswith(prefix) and not value.startswith("postgresql+"):
                return "postgresql+asyncpg://" + value[len(prefix):]
        return value

    @model_validator(mode="after")
    def _require_strong_secret_in_real_envs(self) -> "Settings":
        """En staging/production, exige un JWT_SECRET fuerte (no el de ejemplo).

        Evita desplegar con una clave débil, que permitiría falsificar tokens de
        cualquier tenant. En local/test se permite el valor por defecto por comodidad.
        """
        if self.app_env in ("staging", "production"):
            if self.jwt_secret in _WEAK_SECRETS or len(self.jwt_secret) < _MIN_SECRET_LENGTH:
                raise ValueError(
                    "JWT_SECRET debe ser una clave fuerte "
                    f"(>= {_MIN_SECRET_LENGTH} caracteres, no el valor de ejemplo) "
                    f"en el entorno '{self.app_env}'."
                )
        return self


@lru_cache
def get_settings() -> Settings:
    """Devuelve la instancia única de Settings (cacheada)."""
    return Settings()


settings = get_settings()
