# TechRen EDU marketing site (Next.js)

Creative landing for the education center. Static-exported into `../website/` so Railway / Express keep serving `/` and `/downloads`.

## Develop

```bash
cd web
npm run dev
```

Open http://localhost:3000

## Publish into monorepo website folder

```bash
cd web
npm run build:site
```

This runs `next build` (static export) and copies `out/` → `website/`, **keeping** `website/downloads/` (status.json, installers).
