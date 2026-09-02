# ==========================================
# Stage 1: Build Image
# ==========================================
FROM node:22-alpine AS builder

WORKDIR /app

COPY package*.json ./
COPY tsconfig*.json ./
RUN npm ci

COPY src ./src/
RUN npm run build
RUN npm prune --omit=dev

# ==========================================
# Stage 2: Production Runtime
# ==========================================
FROM node:22-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV PROXY_DATA_PORT=8888
ENV PROXY_CONTROL_PORT=8889

COPY package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist

EXPOSE 8888
EXPOSE 8889

CMD ["node", "dist/proxy.js"]
