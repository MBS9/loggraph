DROP MATERIALIZED VIEW IF EXISTS graph_view;
CREATE MATERIALIZED VIEW IF NOT EXISTS graph_view AS
WITH shared_parts AS (
    SELECT rp1.request_id AS request_1,
        rp2.request_id AS request_2,
        COUNT(*) AS shared_parts_count
    FROM request_to_parts rp1
    JOIN request_to_parts rp2 ON rp1.part_id = rp2.part_id
    WHERE rp1.request_id < rp2.request_id
    GROUP BY rp1.request_id, rp2.request_id
    HAVING COUNT(*) >= 3
)
SELECT r1.hash AS request_1, r2.hash AS request_2, sp.shared_parts_count::float / (r1.part_count + r2.part_count - sp.shared_parts_count)::float AS jaccard_index
FROM shared_parts sp
JOIN requests r1 ON sp.request_1 = r1.id
JOIN requests r2 ON sp.request_2 = r2.id;

GRANT SELECT ON graph_view TO anon;

CREATE OR REPLACE FUNCTION refresh_graph_view()
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW graph_view;
END;
$$;

GRANT EXECUTE ON FUNCTION refresh_graph_view() TO loginserter;
GRANT MAINTAIN ON graph_view TO loginserter;
