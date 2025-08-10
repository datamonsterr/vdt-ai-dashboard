"""Main SDK client for interacting with VDT AI platform."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Optional

from vdt_ai.auth import Authenticator
from vdt_ai.proto.common.v1 import auth_pb2  # type: ignore[import]


@dataclass
class VDTClient:
    """VDT AI client providing authentication via Clerk."""

    api_key: str
    _authenticator: Authenticator | None = None
    _session_token: Optional[str] = None

    def __post_init__(self) -> None:
        self._authenticator = Authenticator(api_key=self.api_key)

    def sign_in(
        self, email: str, password: str, organization_id: str = ""
    ) -> auth_pb2.AuthResponse:  # type: ignore[attr-defined]
        """Sign in a user and store session token."""

        request = auth_pb2.AuthRequest(  # type: ignore[attr-defined]
            email=email, password=password, organization_id=organization_id
        )
        assert self._authenticator is not None
        response = self._authenticator.sign_in(request)
        self._session_token = response.session_token
        return response
