#!/bin/bash
set -e

echo "================================================================="
echo "  RESEARCHVIA - FULLY AUTOMATED PLATFORM DEPLOYMENT & RESTORE   "
echo "================================================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# -----------------------------------------------------------------------------
# 1. Sync .env to all services
# -----------------------------------------------------------------------------
echo "[1/5] Syncing .env to backend services..."
if [ -f ".env" ]; then
    cp .env l-l-backend/.env 2>/dev/null || true
    cp .env automated-api-one/backend/.env 2>/dev/null || true
    echo "✔ .env synced successfully."
else
    echo "❌ Error: .env file not found in $SCRIPT_DIR."
    exit 1
fi

# -----------------------------------------------------------------------------
# 2. Launch / Rebuild Docker Compose Containers
# -----------------------------------------------------------------------------
echo "[2/5] Starting all Docker Compose services..."
docker compose up -d --build
echo "✔ All containers are up and running."

# Wait a few seconds for services to become healthy
echo "Waiting for backend services to initialize..."
sleep 5

# -----------------------------------------------------------------------------
# 3. Automated Uploads Restore (backend-uploads-all.tar.gz) - Skip if already restored
# -----------------------------------------------------------------------------
echo "[3/5] Checking backend uploads directory..."
EXISTING_UPLOADS_SIZE=$(docker exec trading-ll-backend du -s /usr/src/app/app/uploads 2>/dev/null | awk '{print $1}' || echo "0")

if [ "$EXISTING_UPLOADS_SIZE" -gt 100000 ]; then
    echo "✔ Uploads directory is already populated ($EXISTING_UPLOADS_SIZE KB). Skipping extraction."
    docker exec -u 0 trading-ll-backend chown -R node:node /usr/src/app/app/uploads 2>/dev/null || true
    docker exec -u 0 trading-ll-backend chmod -R 755 /usr/src/app/app/uploads 2>/dev/null || true
else
    UPLOADS_ARCHIVE=""
    for loc in "$SCRIPT_DIR/backend-uploads-all.tar.gz" "$SCRIPT_DIR/../backend-uploads-all.tar.gz" "/root/backend-uploads-all.tar.gz"; do
        if [ -f "$loc" ]; then
            UPLOADS_ARCHIVE="$loc"
            break
        fi
    done

    if [ -n "$UPLOADS_ARCHIVE" ]; then
        echo "Streaming and extracting uploads archive from: $UPLOADS_ARCHIVE..."
        docker exec -i trading-ll-backend tar -xzf - -C /usr/src/app/app/uploads/ < "$UPLOADS_ARCHIVE"
        docker exec -u 0 trading-ll-backend chown -R node:node /usr/src/app/app/uploads
        docker exec -u 0 trading-ll-backend chmod -R 755 /usr/src/app/app/uploads
        echo "✔ Uploads restored successfully."
    else
        echo "ℹ No archive found or uploads already up to date."
    fi
fi

# -----------------------------------------------------------------------------
# 4. Automated Database Restores (Postgres & Mongo if backups exist)
# -----------------------------------------------------------------------------
echo "[4/5] Checking for database backup files..."

# PostgreSQL Restore (only if tables don't already exist or if explicitly needed)
PG_BACKUP=""
for loc in "$SCRIPT_DIR/postgres_main_backup.sql" "$SCRIPT_DIR/../postgres_main_backup.sql" "/root/postgres_main_backup.sql"; do
    if [ -f "$loc" ]; then
        PG_BACKUP="$loc"
        break
    fi
done

if [ -n "$PG_BACKUP" ]; then
    echo "PostgreSQL backup file found: $PG_BACKUP"
    echo "ℹ Skipping automatic overwrite. To manually restore, run: docker exec -i trading-postgres psql -U postgres -d trading_platform < $PG_BACKUP"
fi

# MongoDB Restore
MONGO_BACKUP=""
for loc in "$SCRIPT_DIR/mongo_db1.archive" "$SCRIPT_DIR/../mongo_db1.archive" "/root/mongo_db1.archive" "$SCRIPT_DIR/mongo_db2.archive" "$SCRIPT_DIR/../mongo_db2.archive" "/root/mongo_db2.archive"; do
    if [ -f "$loc" ]; then
        MONGO_BACKUP="$loc"
        break
    fi
done

if [ -n "$MONGO_BACKUP" ]; then
    echo "MongoDB backup file found: $MONGO_BACKUP"
    echo "ℹ Skipping automatic overwrite. To manually restore, run: docker cp $MONGO_BACKUP trading-mongo:/tmp/backup.archive && docker exec trading-mongo mongorestore --archive=/tmp/backup.archive --drop"
fi

# -----------------------------------------------------------------------------
# 5. Automated SSL Certificate Generation & Nginx HTTPS Activation
# -----------------------------------------------------------------------------
echo "[5/5] Setting up SSL certificates and HTTPS gateway..."

# Read domain names from .env
DOMAIN_BACKEND=$(grep '^DOMAIN_BACKEND=' .env | cut -d '=' -f2 | tr -d ' "\r\n' || echo "apitest.researchvia.in")
DOMAIN_ADMIN=$(grep '^DOMAIN_ADMIN=' .env | cut -d '=' -f2 | tr -d ' "\r\n' || echo "admintest.researchvia.in")
DOMAIN_AUTOMATED_API=$(grep '^DOMAIN_AUTOMATED_API=' .env | cut -d '=' -f2 | tr -d ' "\r\n' || echo "tradetest.researchvia.in")

echo "Target domains for SSL:"
echo "  - Backend:   $DOMAIN_BACKEND"
echo "  - Admin:     $DOMAIN_ADMIN"
echo "  - Auto API:  $DOMAIN_AUTOMATED_API"

# Request certificates using certbot container via ACME challenge webroot
echo "Requesting Let's Encrypt SSL certificates..."
docker run --rm \
  -v trading_certbot_www:/var/www/certbot \
  -v trading_certbot_certs:/etc/letsencrypt \
  certbot/certbot certonly \
  --webroot \
  -w /var/www/certbot \
  --non-interactive \
  --agree-tos \
  --register-unsafely-without-email \
  -d "$DOMAIN_BACKEND" \
  -d "$DOMAIN_ADMIN" \
  -d "$DOMAIN_AUTOMATED_API" || echo "Certbot attempt completed."

# Check if certificates exist
if docker run --rm -v trading_certbot_certs:/etc/letsencrypt alpine test -f "/etc/letsencrypt/live/$DOMAIN_BACKEND/fullchain.pem" 2>/dev/null; then
    echo "✔ Valid SSL certificates found! Activating HTTPS in Nginx Gateway..."
    cp nginx/templates/default-ssl.conf.template.example nginx/templates/default.conf.template
    docker compose restart gateway
    echo "✔ Gateway restarted with full HTTPS SSL enabled."
else
    echo "ℹ Note: If Let's Encrypt requires ports 80/443 directly or you use Cloudflare SSL, the gateway is currently serving on HTTP."
fi

echo "================================================================="
echo "                   DEPLOYMENT COMPLETE!                         "
echo "================================================================="
docker compose ps
