# ==========================================
# Stage 1: Build Flutter Web Application
# ==========================================
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Build arguments for injecting custom backend domains into Flutter web
ARG API_BASE_URL=http://localhost:8080/api
ARG AUTOMATED_API_BASE_URL=http://localhost:3000

ENV API_BASE_URL=${API_BASE_URL}
ENV AUTOMATED_API_BASE_URL=${AUTOMATED_API_BASE_URL}

# Copy dependency specifications first for caching
COPY pubspec.yaml pubspec.lock ./

RUN flutter config --no-analytics \
    && flutter config --enable-web \
    && flutter pub get

# Copy all source code
COPY . .

# Build web distribution with baked-in environment parameters
RUN flutter build web --release \
    --no-tree-shake-icons \
    --dart-define=API_BASE_URL=${API_BASE_URL} \
    --dart-define=AUTOMATED_API_BASE_URL=${AUTOMATED_API_BASE_URL}

# ==========================================
# Stage 2: High Performance Nginx Web Server
# ==========================================
FROM nginx:alpine AS runner

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy built flutter web bundle
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:80/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
