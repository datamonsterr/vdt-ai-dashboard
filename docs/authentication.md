# Authentication

## Overview
VDT AI uses [Clerk](https://clerk.com) for user authentication and organization (team) management. Both the web dashboard and the Python SDK rely on Clerk to issue and verify session tokens.

## Dashboard
1. Set `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` and `CLERK_SECRET_KEY` in `apps/dashboard/.env.local`.
2. `ClerkProvider` wraps the application and exposes `OrganizationSwitcher` and `UserButton` in the layout for team support.
3. Routes are protected via `authMiddleware`; unauthenticated users are redirected to `/sign-in`.

## Python SDK
The SDK authenticates through Clerk's API using protobuf messages `AuthRequest` and `AuthResponse`.

```python
from vdt_ai import VDTClient

client = VDTClient(api_key="CLERK_API_KEY")
session = client.sign_in("user@example.com", "password", organization_id="org_123")
print(session.session_token)
```

The session token returned by Clerk can be reused for subsequent API calls.
