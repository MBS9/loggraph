CREATE OR REPLACE FUNCTION insert_request(request_hash TEXT, parts JSONB)
RETURNS VOID
LANGUAGE sql
AS $$
WITH inserted_parts AS (
    INSERT INTO request_parts (part_type, data)
    SELECT pt.id, part->>'data'
    FROM jsonb_array_elements(parts) AS part
    JOIN part_types pt ON pt.name = part->>'part_type'
    ON CONFLICT (part_type, data) DO UPDATE SET frequency = request_parts.frequency + 1
    RETURNING id
),
new_request AS (
    INSERT INTO requests (hash, part_count)
    SELECT request_hash, count(*)
    FROM inserted_parts
    ON CONFLICT (hash) DO UPDATE SET frequency = requests.frequency + 1
    RETURNING id
)
INSERT INTO request_to_parts (request_id, part_id)
SELECT nr.id, ip.id
FROM inserted_parts ip, new_request nr
ON CONFLICT DO NOTHING;
$$;

GRANT EXECUTE ON FUNCTION insert_request(TEXT, JSONB) TO loginserter;

CREATE OR REPLACE FUNCTION insert_requests(requests JSONB[])
RETURNS VOID
LANGUAGE sql
AS $$
SELECT insert_request(request->>'request_hash', request->'parts')
FROM unnest(requests) AS request;
$$;

GRANT EXECUTE ON FUNCTION insert_requests(JSONB[]) TO loginserter;
