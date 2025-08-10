from typing import Any

import pytest
import requests
from vdt_ai.auth import Authenticator, ClerkAuthError
from vdt_ai.proto.common.v1 import auth_pb2


class DummyResponse:
    def __init__(self, status_code: int, payload: dict[str, Any]):
        self.status_code = status_code
        self._payload = payload

    def json(self) -> dict[str, Any]:
        return self._payload

    def raise_for_status(self) -> None:
        if self.status_code >= 400:
            raise requests.HTTPError(f"status {self.status_code}")


def test_sign_in_success(monkeypatch: pytest.MonkeyPatch) -> None:
    def fake_post(
        url: str, json: dict[str, Any], headers: dict[str, str], timeout: int
    ) -> DummyResponse:
        return DummyResponse(
            200, {"user_id": "u1", "organization_id": "o1", "session_token": "s1"}
        )

    monkeypatch.setattr("requests.post", fake_post)
    auth = Authenticator(api_key="key")
    request = auth_pb2.AuthRequest(email="a@b.com", password="p", organization_id="o1")
    response = auth.sign_in(request)
    assert response.user_id == "u1"
    assert response.organization_id == "o1"
    assert response.session_token == "s1"


def test_sign_in_error(monkeypatch: pytest.MonkeyPatch) -> None:
    def fake_post(
        url: str, json: dict[str, Any], headers: dict[str, str], timeout: int
    ) -> DummyResponse:
        return DummyResponse(401, {})

    monkeypatch.setattr("requests.post", fake_post)
    auth = Authenticator(api_key="key")
    request = auth_pb2.AuthRequest(email="a@b.com", password="bad")
    with pytest.raises(ClerkAuthError):
        auth.sign_in(request)
