# Dierb self-hosted deployment

## Requirements

- Linux VPS with Docker Engine and Docker Compose v2.
- DNS record for the API hostname.
- TLS certificate files at `deploy/certs/fullchain.pem` and `deploy/certs/privkey.pem`.
- At least 4 GB RAM, 2 CPU cores, and persistent SSD storage.

## First deployment

1. Clone the `dierb-self-hosted-backend` branch.
2. Copy `.env.example` to `.env` and replace every `replace-*` value with independently generated secrets.
3. Set `PUBLIC_API_URL` and `CORS_ORIGINS` to the production HTTPS hostnames.
4. Place the TLS certificate files in `deploy/certs`.
5. Run `docker compose up -d --build`.
6. Check `curl https://YOUR_API_HOST/v1/health` and open `/docs` for the API contract.
7. Run the seed only when required: `docker compose exec backend npm run prisma:seed`. No admin is created unless both seed admin environment values are explicitly supplied.

PostgreSQL, Redis, and MinIO are attached only to the internal Docker network and expose no host ports. Nginx is the sole public entry point.

## Flutter environments

Build each application with a single centrally supplied API endpoint:

```sh
flutter build apk --release --dart-define=DIERB_API_URL=https://api.example.com
```

Use different URLs for development, staging, and production. Never embed database credentials or JWT signing secrets in Flutter.

## Backups

Run `BACKUP_DIR=/secure/backups scripts/backup.sh`. Restore only during a maintenance window using `scripts/restore.sh /secure/backups/TIMESTAMP`. The restore script validates SHA-256 checksums before replacing the database and upload volume.

## Firebase cutover

FCM may remain as an Android transport. The Firebase service-account JSON belongs only in the backend secret manager/environment. Firebase Auth, Firestore, and Storage stay enabled during migration and are removed only after the final data delta import and successful API-mode release.
