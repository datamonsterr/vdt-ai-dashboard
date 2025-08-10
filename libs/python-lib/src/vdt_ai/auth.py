"""Authentication utilities for VDT AI SDK using Clerk."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import requests
from vdt_ai.proto.common.v1 import auth_pb2  # type: ignore[import]


class ClerkAuthError(Exception):
    """Raised when Clerk authentication fails."""


@dataclass
class Authenticator:
    """Authenticate users against Clerk API."""

    api_key: str
    base_url: str = "https://api.clerk.com/v1"

    def sign_in(self, request: auth_pb2.AuthRequest) -> auth_pb2.AuthResponse:  # type: ignore[attr-defined]
        """Sign in a user via Clerk.

        Args:
            request: Authentication request containing email/password/org.

        Returns:
            AuthResponse with session information.
        """

        payload = {
            "identifier": request.email,
            "password": request.password,
        }
        if getattr(request, "organization_id", ""):
            payload["organization_id"] = request.organization_id

        headers = {"Authorization": f"Bearer {self.api_key}"}

        try:
            response = requests.post(
                f"{self.base_url}/sign_in", json=payload, headers=headers, timeout=5
            )
            response.raise_for_status()
        except requests.RequestException as exc:
            raise ClerkAuthError(str(exc)) from exc

        data = response.json()
        return auth_pb2.AuthResponse(  # type: ignore[attr-defined]
            user_id=data.get("user_id", ""),
            organization_id=data.get("organization_id", ""),
            session_token=data.get("session_token", ""),
        )
