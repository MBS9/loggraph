#!/usr/bin/env bash
# Generated with assistance from GitHub Copilot AI.
# Review and validate this script before using it against production data.

set -Eeuo pipefail

usage() {
    cat <<'EOF'
NOTICE: This script was generated with AI assistance. Review it before use.

Usage: ./scripts/download-sample.sh START_DATE END_DATE SSH_HOST

Export production data in [START_DATE, END_DATE) over SSH and replace the
source-data tables in the local PostgreSQL database.

Arguments:
  START_DATE  Inclusive date in YYYY-MM-DD format
  END_DATE    Exclusive date in YYYY-MM-DD format
  SSH_HOST    SSH destination with access to the production PostgreSQL server

Environment:
  LOCAL_DATABASE_URL  Local psql connection URL
                      (default: postgres://postgres:password@localhost:5432/database)
  REMOTE_PGDATABASE   Remote database name (default: loggraph)
  REMOTE_PGHOST       Remote PostgreSQL host; omit for the Unix socket
  REMOTE_PGPORT       Remote PostgreSQL port; omit for the default
  REMOTE_PGUSER       Remote PostgreSQL user; omit to use the SSH user's peer role
  REMOTE_USE_SUDO     Run psql as the postgres OS user via sudo (default: 1)
  SKIP_GRAPH_REFRESH  Set to 1 to leave the local materialized view unchanged

Remote PostgreSQL authentication is expected to use peer authentication or
the SSH user's ~/.pgpass file. Passwords are not passed as script arguments.
EOF
}

fail() {
    echo "Error: $*" >&2
    exit 1
}

validate_date() {
    local value=$1

    [[ $value =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] ||
        fail "invalid date '$value'; expected YYYY-MM-DD"

    date -d "$value" '+%Y-%m-%d' 2>/dev/null | grep -qx "$value" ||
        fail "invalid calendar date '$value'"
}

if [[ $# -ne 3 ]]; then
    usage >&2
    exit 2
fi

start_date=$1
end_date=$2
remote_host=$3

validate_date "$start_date"
validate_date "$end_date"

[[ $start_date < $end_date ]] || fail "START_DATE must be earlier than END_DATE"

command -v ssh >/dev/null || fail "ssh is required"
command -v scp >/dev/null || fail "scp is required"
command -v psql >/dev/null || fail "psql is required"
command -v tar >/dev/null || fail "tar is required"

local_database_url=${LOCAL_DATABASE_URL:-postgres://postgres:password@localhost:5432/database}
remote_database=${REMOTE_PGDATABASE:-loggraph}
remote_pg_host=${REMOTE_PGHOST:-}
remote_pg_port=${REMOTE_PGPORT:-}
remote_pg_user=${REMOTE_PGUSER:-}
remote_use_sudo=${REMOTE_USE_SUDO:-1}

work_dir=$(mktemp -d /tmp/loggraph-download.XXXXXX)
archive="$work_dir/sample.tar.gz"
extract_dir="$work_dir/data"
remote_export_script=
remote_archive=
mkdir "$extract_dir"

cleanup() {
    if [[ -n $remote_export_script || -n $remote_archive ]]; then
        ssh "$remote_host" "rm -f -- $(printf '%q' "$remote_export_script") $(printf '%q' "$remote_archive")" \
            >/dev/null 2>&1 || true
    fi
    rm -rf "$work_dir"
}
trap cleanup EXIT

echo "Exporting requests created from $start_date (inclusive) to $end_date (exclusive)..." >&2

cat >"$work_dir/remote-export.sh" <<'REMOTE_SCRIPT'
set -Eeuo pipefail

start_date=$1
end_date=$2
database=$3
pg_host=$4
pg_port=$5
pg_user=$6
output_archive=${7:-}

export_dir=$(mktemp -d /tmp/loggraph-export.XXXXXX)
cleanup_export() {
    rm -rf "$export_dir"
}
trap cleanup_export EXIT

psql_args=(--quiet --set=ON_ERROR_STOP=1 --dbname "$database")
[[ -z $pg_host ]] || psql_args+=(--host "$pg_host")
[[ -z $pg_port ]] || psql_args+=(--port "$pg_port")
[[ -z $pg_user ]] || psql_args+=(--username "$pg_user")

cat >"$export_dir/export.sql" <<SQL
\set ON_ERROR_STOP on
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY;

\copy (SELECT pt.id, pt.name, pt.description FROM public.part_types AS pt WHERE EXISTS (SELECT 1 FROM public.request_parts AS rp JOIN public.request_to_parts AS rtp ON rtp.part_id = rp.id JOIN public.requests AS r ON r.id = rtp.request_id WHERE rp.part_type = pt.id AND r.created_at >= TIMESTAMP '$start_date' AND r.created_at < TIMESTAMP '$end_date') ORDER BY pt.id) TO '$export_dir/part_types.csv' WITH (FORMAT csv, HEADER true)
\copy (SELECT r.id, r.ext_id, r.created_at, r.last_seen_at, r.hash, r.frequency FROM public.requests AS r WHERE r.created_at >= TIMESTAMP '$start_date' AND r.created_at < TIMESTAMP '$end_date' ORDER BY r.ext_id) TO '$export_dir/requests.csv' WITH (FORMAT csv, HEADER true)
\copy (SELECT rp.id, rp.part_type, rp.data, rp.created_at, rp.frequency, rp.excluded FROM public.request_parts AS rp WHERE EXISTS (SELECT 1 FROM public.request_to_parts AS rtp JOIN public.requests AS r ON r.id = rtp.request_id WHERE rtp.part_id = rp.id AND r.created_at >= TIMESTAMP '$start_date' AND r.created_at < TIMESTAMP '$end_date') ORDER BY rp.id) TO '$export_dir/request_parts.csv' WITH (FORMAT csv, HEADER true)
\copy (SELECT rtp.request_id, rtp.part_id FROM public.request_to_parts AS rtp JOIN public.requests AS r ON r.id = rtp.request_id WHERE r.created_at >= TIMESTAMP '$start_date' AND r.created_at < TIMESTAMP '$end_date' ORDER BY rtp.part_id, rtp.request_id) TO '$export_dir/request_to_parts.csv' WITH (FORMAT csv, HEADER true)

COMMIT;
SQL

psql "${psql_args[@]}" --file "$export_dir/export.sql"

if [[ -n $output_archive ]]; then
    tar -C "$export_dir" -czf "$output_archive" \
        part_types.csv requests.csv request_parts.csv request_to_parts.csv
    chmod 0644 "$output_archive"
else
    # Keep SSH stdout dedicated to the archive; status goes to stderr.
    tar -C "$export_dir" -czf - \
        part_types.csv requests.csv request_parts.csv request_to_parts.csv
fi
REMOTE_SCRIPT

if [[ $remote_use_sudo == 1 ]]; then
    run_id="${work_dir##*/}"
    remote_export_script="/tmp/loggraph-export-$run_id.sh"
    remote_archive="/tmp/loggraph-export-$run_id.tar.gz"
    scp -q "$work_dir/remote-export.sh" "$remote_host:$remote_export_script"

    printf -v remote_command 'sudo -u postgres bash %q %q %q %q %q %q %q %q' \
        "$remote_export_script" \
        "$start_date" \
        "$end_date" \
        "$remote_database" \
        "$remote_pg_host" \
        "$remote_pg_port" \
        "$remote_pg_user" \
        "$remote_archive"

    ssh -tt "$remote_host" "$remote_command"
    scp -q "$remote_host:$remote_archive" "$archive"
elif [[ $remote_use_sudo == 0 ]]; then
    printf -v remote_command 'bash -s -- %q %q %q %q %q %q' \
        "$start_date" \
        "$end_date" \
        "$remote_database" \
        "$remote_pg_host" \
        "$remote_pg_port" \
        "$remote_pg_user"
    ssh "$remote_host" "$remote_command" <"$work_dir/remote-export.sh" >"$archive"
else
    fail "REMOTE_USE_SUDO must be 0 or 1"
fi

tar -tzf "$archive" >/dev/null ||
    fail "the remote server did not return a valid export archive"
tar -xzf "$archive" -C "$extract_dir"

for file in part_types.csv requests.csv request_parts.csv request_to_parts.csv; do
    [[ -f "$extract_dir/$file" ]] || fail "export archive is missing $file"
done

request_count=$(( $(wc -l <"$extract_dir/requests.csv") - 1 ))
(( request_count > 0 )) ||
    fail "no requests were found in the selected date range; local data was not changed"

cat >"$work_dir/import.sql" <<SQL
\set ON_ERROR_STOP on
BEGIN;

CREATE TEMP TABLE imported_part_types (
    LIKE public.part_types INCLUDING DEFAULTS
) ON COMMIT DROP;
CREATE TEMP TABLE imported_requests (
    LIKE public.requests INCLUDING DEFAULTS
) ON COMMIT DROP;
CREATE TEMP TABLE imported_request_parts (
    LIKE public.request_parts INCLUDING DEFAULTS
) ON COMMIT DROP;
CREATE TEMP TABLE imported_request_to_parts (
    LIKE public.request_to_parts INCLUDING DEFAULTS
) ON COMMIT DROP;

\copy imported_part_types (id, name, description) FROM '$extract_dir/part_types.csv' WITH (FORMAT csv, HEADER true)
\copy imported_requests (id, ext_id, created_at, last_seen_at, hash, frequency) FROM '$extract_dir/requests.csv' WITH (FORMAT csv, HEADER true)
\copy imported_request_parts (id, part_type, data, created_at, frequency, excluded) FROM '$extract_dir/request_parts.csv' WITH (FORMAT csv, HEADER true)
\copy imported_request_to_parts (request_id, part_id) FROM '$extract_dir/request_to_parts.csv' WITH (FORMAT csv, HEADER true)

DO \$\$
BEGIN
    IF (SELECT count(*) FROM imported_requests) = 0 THEN
        RAISE EXCEPTION 'the selected date range contains no requests';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM imported_request_parts AS rp
        LEFT JOIN imported_part_types AS pt ON pt.id = rp.part_type
        WHERE pt.id IS NULL
    ) THEN
        RAISE EXCEPTION 'export is missing a referenced part type';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM imported_request_to_parts AS rtp
        LEFT JOIN imported_requests AS r ON r.id = rtp.request_id
        LEFT JOIN imported_request_parts AS rp ON rp.id = rtp.part_id
        WHERE r.id IS NULL OR rp.id IS NULL
    ) THEN
        RAISE EXCEPTION 'export contains broken request-to-part references';
    END IF;
END;
\$\$;

TRUNCATE TABLE
    public.request_to_parts,
    public.requests,
    public.request_parts,
    public.part_types
CASCADE;

INSERT INTO public.part_types (id, name, description)
SELECT id, name, description
FROM imported_part_types;

INSERT INTO public.requests (id, ext_id, created_at, last_seen_at, hash, frequency)
OVERRIDING SYSTEM VALUE
SELECT id, ext_id, created_at, last_seen_at, hash, frequency
FROM imported_requests;

INSERT INTO public.request_parts (id, part_type, data, created_at, frequency, excluded)
SELECT id, part_type, data, created_at, frequency, excluded
FROM imported_request_parts;

INSERT INTO public.request_to_parts (request_id, part_id)
SELECT request_id, part_id
FROM imported_request_to_parts;

SELECT setval(
    pg_get_serial_sequence('public.requests', 'ext_id'),
    (SELECT max(ext_id) FROM public.requests),
    true
);

\if :refresh_graph
SELECT 'REFRESH MATERIALIZED VIEW public.graph_view'
WHERE EXISTS (
    SELECT 1
    FROM pg_catalog.pg_matviews
    WHERE schemaname = 'public'
      AND matviewname = 'graph_view'
)
\gexec
\endif

COMMIT;
SQL

echo "Replacing local source data with $request_count requests..." >&2
refresh_graph=1
if [[ ${SKIP_GRAPH_REFRESH:-0} == 1 ]]; then
    refresh_graph=0
else
    echo "Refreshing local graph_view in the same transaction..." >&2
fi

psql "$local_database_url" \
    --set=ON_ERROR_STOP=1 \
    --set="refresh_graph=$refresh_graph" \
    --file "$work_dir/import.sql"

echo "Local sample import completed successfully." >&2
