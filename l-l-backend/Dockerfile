# ==========================================
# Stage 1: Build & Dependencies
# ==========================================
FROM node:22-alpine AS builder

WORKDIR /usr/src/app

COPY package*.json ./
COPY prisma ./prisma/

RUN npm install

COPY . .

RUN npx prisma generate

# ==========================================
# Stage 2: Production Runtime
# ==========================================
FROM node:22-alpine AS runner

WORKDIR /usr/src/app

RUN apk add --no-cache curl openssl libc6-compat

COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder /usr/src/app/package*.json ./
COPY --from=builder /usr/src/app/prisma ./prisma
COPY --from=builder /usr/src/app/app ./app
COPY --from=builder /usr/src/app/server.js ./server.js
COPY --from=builder /usr/src/app/prisma.config.* ./

# Ensure standard upload directory hierarchy exists
RUN mkdir -p app/uploads/kycimg app/uploads/kycvid app/uploads/reports app/uploads/qrcodes

EXPOSE 8080

ENV NODE_ENV=production
ENV PORT=8080

HEALTHCHECK --interval=20s --timeout=5s --start-period=15s --retries=3 \
  CMD curl -f http://127.0.0.1:8080/api/health || curl -f http://127.0.0.1:8080/ || exit 1

CMD ["node", "server.js"]
