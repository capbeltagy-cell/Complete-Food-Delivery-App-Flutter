#!/usr/bin/env sh
set -eu
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
target="${BACKUP_DIR:-./backups}/$stamp"
mkdir -p "$target"

docker compose exec -T postgres pg_dump -U "${POSTGRES_USER:-dierb}" -d "${POSTGRES_DB:-dierb}" -Fc > "$target/postgres.dump"

minio_container="$(docker compose ps -q minio)"
test -n "$minio_container"
docker run --rm --volumes-from "$minio_container":ro -v "$(pwd)/$target:/backup" alpine tar czf /backup/minio-data.tar.gz -C /data .

(cd "$target" && sha256sum postgres.dump minio-data.tar.gz > SHA256SUMS)
echo "$target"
