# ==========================================
# Stage 1: Build Image
# ==========================================
FROM node:20-alpine AS builder

WORKDIR /usr/src/app

COPY package*.json ./
COPY prisma ./prisma/

RUN npm ci

COPY . .

RUN npx prisma generate
RUN npm run build

# Clean dev dependencies
RUN npm prune --production

# ==========================================
# Stage 2: Production Runtime
# ==========================================
FROM node:20-alpine AS runner

WORKDIR /usr/src/app

# Install native packages needed for pg healthchecks
RUN apk add --no-cache curl postgresql-client

COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder /usr/src/app/dist ./dist
COPY --from=builder /usr/src/app/package*.json ./
COPY --from=builder /usr/src/app/prisma ./prisma

EXPOSE 3000

ENV NODE_ENV=production

CMD ["node", "dist/src/main.js"]
