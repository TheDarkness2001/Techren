# TechRen EDU — Deployment Guide

**Phase 10.7** — Docker, CI, and production environment setup.

---

## 1. Environments

| Environment | API | Database | Bootstrap |
|-------------|-----|----------|-----------|
| **Development** | `npm start` locally | In-memory MongoDB fallback or local Mongo | Demo accounts auto-seeded |
| **Docker stack** | `docker compose up` | MongoDB 7 container | Run `npm run seed` once |
| **Staging / Production** | VPS + PM2 or container | MongoDB Atlas M10+ replica set | `npm run seed` for founder only |

---

## 2. Required environment variables

| Variable | Required | Description |
|----------|----------|-------------|
| `JWT_SECRET` | Yes | Long random string (32+ chars) |
| `MONGO_URI` | Yes (prod) | Atlas connection string or `mongodb://mongo:27017/techren_edu` in Docker |
| `NODE_ENV` | Recommended | `development` or `production` |
| `PORT` | No | Default `5002` |
| `FOUNDER_EMAIL` | No | First founder account email |
| `FOUNDER_PASSWORD` | Yes (prod) | Strong password for founder seed |
| `JWT_ACCESS_EXPIRE` | No | Default `15m` |
| `JWT_REFRESH_EXPIRE` | No | Default `7d` |
| `GAMIFICATION_ENABLED` | No | Default `true` |
| `WALLET_ENABLED` | No | Default `false` |
| `FRONTEND_URL` | Prod CORS | Allowed origin when `NODE_ENV=production` |
| `FIREBASE_*` | Push only | FCM credentials (optional) |

Copy `backend/.env.example` for local development. Copy `.env.docker.example` → `.env.docker` for Docker Compose.

> **Security:** Demo accounts are only auto-created when `NODE_ENV` is not `production`. In production, run `npm run seed` once to create the founder, then change passwords immediately.

---

## 3. Docker Compose (local staging stack)

```bash
# From repo root
cp .env.docker.example .env.docker
# Edit JWT_SECRET and FOUNDER_PASSWORD

docker compose --env-file .env.docker up -d --build
```

API: `http://localhost:5002/api/v1`  
Health: `GET /api/v1/health`

Seed founder (first deploy only):

```bash
docker compose exec api node scripts/seed.js
```

Stop and remove volumes:

```bash
docker compose down -v
```

### Volumes

- `mongo_data` — database persistence
- `uploads_data` — DOCX/audio/image uploads (`/api/v1/uploads`)

---

## 4. MongoDB Atlas (production)

1. Create a **M10+** cluster with replica set enabled.
2. Network access: allow VPS IP or `0.0.0.0/0` with strong credentials (prefer IP allowlist).
3. Database user with read/write on `techren_edu`.
4. Connection string example:

```
MONGO_URI=mongodb+srv://user:pass@cluster.mongodb.net/techren_edu?retryWrites=true&w=majority
```

---

## 5. VPS deployment (PM2)

```bash
# On Ubuntu 22.04+
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs git

cd /opt/techren-edu/backend
cp .env.example .env
# Set NODE_ENV=production, MONGO_URI, JWT_SECRET, FOUNDER_PASSWORD, FRONTEND_URL

npm ci --omit=dev
npm run seed    # first deploy only
```

### PM2 ecosystem

```bash
npm install -g pm2
pm2 start src/server.js --name techren-api
pm2 save
pm2 startup
```

Reverse proxy (Nginx) example:

```nginx
server {
  listen 443 ssl;
  server_name api.techrenacademy.com;

  location / {
    proxy_pass http://127.0.0.1:5002;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    client_max_body_size 20M;
  }
}
```

---

## 6. Flutter client builds

Set the API URL at build time:

```bash
cd techren_edu

# Windows
flutter build windows --dart-define=API_BASE_URL=https://api.techrenacademy.com/api/v1

# Android release
flutter build apk --dart-define=API_BASE_URL=https://api.techrenacademy.com/api/v1

# Android emulator (local API)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5002/api/v1

# iOS
flutter build ios --dart-define=API_BASE_URL=https://api.techrenacademy.com/api/v1
```

Default (no define): `http://localhost:5002/api/v1`

---

## 7. CI pipeline

GitHub Actions workflow: `.github/workflows/ci.yml`

| Job | Steps |
|-----|-------|
| **backend** | `npm ci` → `npm test` (all `scripts/test-*.js`) |
| **flutter** | `flutter pub get` → `flutter analyze` |

Run backend tests locally:

```bash
cd backend
JWT_SECRET=local-test-secret-minimum-32-characters npm test
```

---

## 8. Production checklist

- [ ] `NODE_ENV=production`
- [ ] Strong `JWT_SECRET` and founder password
- [ ] MongoDB Atlas with backups enabled
- [ ] HTTPS termination (Nginx / Cloudflare)
- [ ] `FRONTEND_URL` set for CORS
- [ ] Upload volume backed up
- [ ] Firebase credentials for push (if notifications enabled)
- [ ] Rate limits and firewall reviewed
- [ ] Demo seed disabled (`ensureDevAccounts` skips production automatically)
- [ ] Flutter apps built with production `API_BASE_URL`

---

## 9. Health monitoring

```
GET /api/v1/health
```

Response includes `status`, `uptime`, and `timestamp` — use for load balancer and uptime checks.

---

*Previous: [UI Wireframes](./07-UI-WIREFRAMES.md) · [Project README](./README.md)*
