"""Contratos (Pydantic) del módulo de autenticación."""

from typing import Annotated

from pydantic import BaseModel, EmailStr, Field

Slug = Annotated[str, Field(min_length=2, max_length=100, pattern=r"^[a-z0-9]+(?:-[a-z0-9]+)*$")]
Password = Annotated[str, Field(min_length=8, max_length=128)]


class RegisterRequest(BaseModel):
    company_name: Annotated[str, Field(min_length=2, max_length=200)]
    company_slug: Slug
    email: EmailStr
    password: Password


class LoginRequest(BaseModel):
    company_slug: Slug
    email: EmailStr
    password: Password


class ResetPasswordRequest(BaseModel):
    company_slug: Slug
    email: EmailStr
    new_password: Password


class RefreshRequest(BaseModel):
    refresh_token: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
