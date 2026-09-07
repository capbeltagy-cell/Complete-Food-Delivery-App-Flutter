#!/usr/bin/env sh
set -eu
source_dir="${1:?Usage: scripts/restore.sh BACKUP_DIRECTORY}"
test -f "$source_dir/postgres.dump"
test -f "$source_dir/minio-data.tar.gz"
test -f "$source_dir/SHA256SUMS"
(cd "$source_dir" && sha256sum -c SHA256SUMS)

docker compose exec -T postgres pg_restore --clean --if-exists --no-owner -U "${POSTGRES_USER:-dierb}" -d "${POSTGRES_DB:-dierb}" < "$source_dir/postgres.dump"

minio_container="$(docker compose ps -q minio)"
test -n "$minio_container"
docker compose stop minio
docker run --rm --volumes-from "$minio_container" -v "$(pwd)/$source_dir:/backup:ro" alpine sh -c 'find /data -mindepth 1 -delete && tar xzf /backup/minio-data.tar.gz -C /data'
docker compose start minio
