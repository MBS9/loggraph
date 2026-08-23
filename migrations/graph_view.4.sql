DROP MATERIALIZED VIEW IF EXISTS graph_view;
CREATE MATERIALIZED VIEW IF NOT EXISTS graph_view AS
WITH shared_parts AS (
    SELECT rp1.request_id AS request_1,
        rp2.request_id AS request_2,
        COUNT(*) AS shared_parts_count
    FROM request_to_parts rp1
    JOIN request_to_parts rp2 ON rp1.part_id = rp2.part_id
    JOIN request_parts p ON rp1.part_id = p.id
    WHERE p.excluded = FALSE
      AND rp1.request_id < rp2.request_id
    GROUP BY rp1.request_id, rp2.request_id
),
non_excluded_parts AS (
    SELECT r.id AS request_id, COUNT(*) AS non_excluded_count
    FROM requests r
    JOIN request_to_parts rtp ON r.id = rtp.request_id
    JOIN request_parts rp ON rtp.part_id = rp.id
    WHERE rp.excluded = FALSE
    GROUP BY r.id
)
SELECT r1.hash AS request_1,
    r2.hash AS request_2,
    sp.shared_parts_count::float / (
        nep1.non_excluded_count + nep2.non_excluded_count - sp.shared_parts_count
    )::float AS jaccard_index
FROM shared_parts sp
JOIN requests r1 ON sp.request_1 = r1.id
JOIN non_excluded_parts nep1 ON sp.request_1 = nep1.request_id
JOIN requests r2 ON sp.request_2 = r2.id
JOIN non_excluded_parts nep2 ON sp.request_2 = nep2.request_id;

CREATE UNIQUE INDEX idx_graph_view_request_1_request_2 ON graph_view(request_1, request_2);

GRANT SELECT ON graph_view TO anon;

CREATE OR REPLACE FUNCTION refresh_graph_view()
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY graph_view;
END;
$$;

GRANT EXECUTE ON FUNCTION refresh_graph_view() TO loginserter;
GRANT MAINTAIN ON graph_view TO loginserter;
