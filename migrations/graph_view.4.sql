CREATE TABLE loggraph_config (
    id SERIAL PRIMARY KEY,
    key TEXT NOT NULL,
    value TEXT NOT NULL
);

INSERT INTO loggraph_config (key, value) VALUES ('min_jaccard_index', '0.2');

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
),
full_graph AS (
    SELECT sp.request_1 AS request_1,
        sp.request_2 AS request_2,
        sp.shared_parts_count::float / (
            nep1.non_excluded_count + nep2.non_excluded_count - sp.shared_parts_count
        )::float AS jaccard_index
    FROM shared_parts sp
    JOIN non_excluded_parts nep1 ON sp.request_1 = nep1.request_id
    JOIN non_excluded_parts nep2 ON sp.request_2 = nep2.request_id
)
SELECT * FROM full_graph
WHERE jaccard_index > (SELECT value::float FROM loggraph_config WHERE key = 'min_jaccard_index');

CREATE UNIQUE INDEX idx_graph_view_request_1_request_2 ON graph_view(request_1, request_2);
CREATE INDEX idx_graph_view_jaccard_index ON graph_view(jaccard_index);

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
