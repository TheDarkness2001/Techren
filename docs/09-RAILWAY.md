# Deploy TechRen EDU on Railway (alongside the existing SMS / PWA)

**Goal:** New Railway service for TechRen EDU API + download site.  
**Do not touch** the existing **SMS** Railway service used by the student PWA.

---

## Architecture

| Service | Who uses it | Status |
|---------|-------------|--------|
| Railway **SMS** (existing) | Student PWA | Leave running — unchanged |
| Railway **TechRen EDU** (new) | Windows / Android apps + download page | Create this |
| MongoDB Atlas | Prefer a **separate** DB name (`techren_edu`) | Recommended |

They do not block each other when they have different Railway URLs.

---

## 1. Push this repo to GitHub

Repo already used: `https://github.com/TheDarkness2001/TechRen-app.git`

Commit and push the Railway config (`railway.toml`, path helpers, this doc) if not already on GitHub.

---

## 2. Create a NEW Railway service

1. Open [Railway](https://railway.app) → same project as SMS is fine.
2. **New → GitHub Repo** → select `TechRen-app` (or your fork).
3. **Do not** reconnect / redeploy the SMS service to this repo.
4. Settings:
   - **Root Directory:** leave empty (whole monorepo)
   - Build / start come from root `railway.toml`
5. **Networking → Generate Domain**  
   Copy the URL, e.g. `https://techren-edu-production-xxxx.up.railway.app`

---

## 3. Variables

Use `backend/.env.railway.example` as the checklist.

Minimum for production boot:

| Variable | Notes |
|----------|--------|
| `NODE_ENV` | `production` |
| `MONGO_URI` | Atlas URI; use DB name `techren_edu` (not the SMS DB if possible) |
| `JWT_SECRET` | 32+ chars, **new** secret (not SMS) |
| `JWT_REFRESH_SECRET` | 32+ chars, **different** from `JWT_SECRET` |
| `FOUNDER_PASSWORD` | Strong; not `Founder123!` |
| `FOUNDER_EMAIL` | Your founder login |
| `FRONTEND_URL` | This service’s public `https://…up.railway.app` URL |

Optional:

| Variable | Notes |
|----------|--------|
| `UPLOADS_DIR` | e.g. `/data/uploads` if you mount a Volume at `/data` |
| `JWT_ACCESS_EXPIRE` / `JWT_REFRESH_EXPIRE` | Defaults `15m` / `7d` |

Redeploy after saving variables.

---

## 4. Volume (recommended)

Railway’s disk is wiped on redeploy. For images/audio:

1. Service → **Volumes** → add volume mounted at `/data`
2. Set `UPLOADS_DIR=/data/uploads`

---

## 5. Verify

```text
https://YOUR-SERVICE.up.railway.app/
https://YOUR-SERVICE.up.railway.app/api/v1/health
```

- `/` → TechRen download landing page  
- `/api/v1/health` → `200`  

Seed founder once (Railway shell or one-off):

```bash
cd backend && node scripts/seed.js
```

---

## 6. Rebuild native apps for Railway

On your PC (requires HTTPS production API):

```powershell
.\scripts\build-release-apps.ps1 -ApiBaseUrl "https://YOUR-SERVICE.up.railway.app/api/v1"
```

Then upload installers (APK / setup.exe) to GitHub Releases or another host, and point the download page at those URLs (Railway disk won’t keep large binaries across redeploys unless you use a volume / external storage).

---

## 7. PWA stays safe

| Action | Effect on student PWA |
|--------|------------------------|
| Create new TechRen Railway service | None |
| Change variables only on the new service | None |
| Redeploy / overwrite **SMS** with TechRen code | **May break PWA** — don’t do this |

---

## Troubleshooting

| Symptom | Likely cause |
|---------|----------------|
| Deploy crash: JWT_REFRESH_SECRET | Missing or same as JWT_SECRET |
| Deploy crash: FOUNDER_PASSWORD | Missing or weak default |
| Mongo connection error | Atlas IP allowlist / wrong URI |
| `/` is 404 / empty | Website folder not in deploy — use repo-root deploy (`railway.toml`) |
| Uploads vanish after redeploy | No Volume / `UPLOADS_DIR` |
