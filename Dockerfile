# Monorepo deploy: API (backend/) + modern landing (website1 → website/)
FROM node:20-alpine AS landing
WORKDIR /landing
COPY website1/package.json website1/package-lock.json ./
RUN npm ci
COPY website1 ./
RUN npm run build

FROM node:20-alpine
WORKDIR /app

COPY backend/package.json backend/package-lock.json ./backend/
RUN cd backend && npm ci --omit=dev

COPY backend ./backend
# Vite build output + keep installer status/downloads folder
COPY --from=landing /landing/dist ./website
COPY website/downloads ./website/downloads

WORKDIR /app/backend

ENV NODE_ENV=production
ENV PORT=8080
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=25s --retries=3 \
  CMD node -e "require('http').get('http://127.0.0.1:'+(process.env.PORT||8080)+'/api/v1/health',r=>{process.exit(r.statusCode===200?0:1)}).on('error',()=>process.exit(1))"

CMD ["node", "src/server.js"]
