#!/usr/bin/env sh
set -eu
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
target="${BACKUP_DIR:-./backups}/$stamp"
mkdir -p "$target"
docker compose exec -T postgres pg_dump -U "${POSTGRES_USER:-dierb}" -d "${POSTGRES_DB:-dierb}" -Fc > "$target/postgres.dump"
docker run --rm -v dierb-production_uploads_data:/source:ro -v "$(pwd)/$target:/backup" alpine tar czf /backup/uploads.tar.gz -C /source .
sha256sum "$target"/* > "$target/SHA256SUMS"
echo "$target"
