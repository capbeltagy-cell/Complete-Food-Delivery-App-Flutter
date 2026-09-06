#!/usr/bin/env sh
set -eu
source_dir="${1:?Usage: scripts/restore.sh BACKUP_DIRECTORY}"
test -f "$source_dir/postgres.dump"
test -f "$source_dir/uploads.tar.gz"
(cd "$source_dir" && sha256sum -c SHA256SUMS)
docker compose exec -T postgres pg_restore --clean --if-exists --no-owner -U "${POSTGRES_USER:-dierb}" -d "${POSTGRES_DB:-dierb}" < "$source_dir/postgres.dump"
docker run --rm -v dierb-production_uploads_data:/target -v "$(pwd)/$source_dir:/backup:ro" alpine sh -c 'find /target -mindepth 1 -delete && tar xzf /backup/uploads.tar.gz -C /target'
