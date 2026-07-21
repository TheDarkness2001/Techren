# Web token storage — threat model (M9)

## Context

The Flutter web client stores access and refresh JWTs via `flutter_secure_storage`.
On **mobile / desktop**, that maps to OS keychain / Keystore-backed storage.
On **web**, the plugin falls back to browser storage that is **not** equivalent to a platform keychain.

## Assets

| Asset | Sensitivity |
|-------|-------------|
| Access JWT (~15m) | High — API bearer credential |
| Refresh JWT (~7d) | Critical — can mint new access tokens |
| Cached user JSON | Medium — PII / role hints |

## Threats (web)

1. **XSS** — script in the origin can read tokens from storage and call the API as the user.
2. **Shared device / shoulder surfing** — long-lived refresh tokens survive tab close until logout or expiry.
3. **MITM** — if HTTP is used (debug only), tokens can be intercepted. Release builds require HTTPS `API_BASE_URL`.
4. **CSRF** — less relevant for Bearer-in-header APIs; still harden cookie sessions if you migrate later.

## Mitigations already in place

- Short access-token lifetime; refresh rejection as access (`typ` / `type` checks).
- Refresh tokens hashed at rest in MongoDB and revocable on logout.
- Public auth routes do not attach stale Bearer headers.
- Concurrent refresh queuing; failed refresh forces client unauthenticated state.
- XSS body sanitization + Helmet on API; CORS allowlist in production.

## Recommended follow-ups

1. Prefer **HttpOnly Secure SameSite cookies** for refresh on web (SPA + CSRF double-submit), keep access in memory only.
2. Enforce strong **CSP** on any web host that serves the Flutter app.
3. Idle session timeout on the client (e.g. 30–60 minutes of inactivity → logout).
4. Do not treat Flutter web as PCI / high-assurance for wallet funds without a real payment provider and server-side session model.

## Acceptable use today

Local / branch-office kiosk and authenticated staff/student use over HTTPS behind a trusted domain is acceptable if XSS surface stays low. Do **not** treat current web token storage as safe against a successful XSS on the same origin.
