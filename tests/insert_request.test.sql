\set ON_ERROR_STOP true

CREATE OR REPLACE FUNCTION verify_request_inserted(request_hash TEXT, expected_parts JSONB)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    actual_parts JSONB;
    is_valid BOOLEAN;
BEGIN
    SELECT jsonb_agg(jsonb_build_object('part_type', pt.name, 'data', rp.data, 'frequency', rp.frequency)) INTO actual_parts
    FROM requests r
    JOIN request_to_parts rtp ON r.id = rtp.request_id
    JOIN request_parts rp ON rtp.part_id = rp.id
    JOIN part_types pt ON rp.part_type = pt.id
    WHERE r.hash = request_hash
    GROUP BY r.id;

    is_valid := actual_parts = expected_parts;
    IF NOT is_valid THEN
        RAISE EXCEPTION 'Verification failed for request_hash: %, expected_parts: %, actual_parts: %', request_hash, expected_parts, actual_parts;
    END IF;
    RETURN is_valid;
END;
$$;

CREATE OR REPLACE FUNCTION verify_frequency_increment(request_hash TEXT, expected_frequency INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    actual_frequency INT;
    result BOOLEAN;
BEGIN
    SELECT frequency INTO actual_frequency
    FROM requests
    WHERE hash = request_hash;
    result := actual_frequency = expected_frequency;
    IF NOT result THEN
        RAISE EXCEPTION 'Frequency verification failed for request_hash: %, expected_frequency: %, actual_frequency: %', request_hash, expected_frequency, actual_frequency;
    END IF;
    RETURN result;
END;
$$;

--- Ensure db is empty before running this test. ---
TRUNCATE TABLE request_parts CASCADE;
TRUNCATE TABLE requests CASCADE;
TRUNCATE TABLE request_to_parts CASCADE;
--- Yayy!! Now its empty. ---

--- Ensure all the needed request parts exist in the part_types table ---
INSERT INTO part_types (name, description) VALUES ('type1', 'description1'),
('type2', 'description2'),
('type3', 'description3')
ON CONFLICT (name) DO NOTHING;

--- insert a request with 3 parts ---
SELECT insert_request('hash1', '[{"part_type": "type1", "data": "data1"}, {"part_type": "type2", "data": "data2"}, {"part_type": "type3", "data": "data3"}]');

--- Verify that the request was inserted correctly ---

SELECT verify_request_inserted('hash1', '[{"part_type": "type1", "data": "data1", "frequency": 1}, {"part_type": "type2", "data": "data2", "frequency": 1}, {"part_type": "type3", "data": "data3", "frequency": 1}]'::jsonb);
SELECT verify_frequency_increment('hash1', 1);

--- insert the same request again to test frequency increment
SELECT insert_request('hash1', '[{"part_type": "type1", "data": "data1"}, {"part_type": "type2", "data": "data2"}, {"part_type": "type3", "data": "data3"}]');

SELECT verify_request_inserted('hash1', '[{"part_type": "type1", "data": "data1", "frequency": 2}, {"part_type": "type2", "data": "data2", "frequency": 2}, {"part_type": "type3", "data": "data3", "frequency": 2}]'::jsonb);
SELECT verify_frequency_increment('hash1', 2);

--- insert different request, with some overlapping parts to test frequency increment for parts
SELECT insert_request('hash2', '[{"part_type": "type1", "data": "data1"}, {"part_type": "type2", "data": "data2"}, {"part_type": "type3", "data": "data4"}]');

SELECT verify_request_inserted('hash2', '[{"part_type": "type1", "data": "data1", "frequency": 3}, {"part_type": "type2", "data": "data2", "frequency": 3}, {"part_type": "type3", "data": "data4", "frequency": 1}]'::jsonb);
SELECT verify_frequency_increment('hash2', 1);
SELECT verify_frequency_increment('hash1', 2);

-- same part can appear multiple times in the same request

SELECT insert_request('hash3', '[{"part_type": "type1", "data": "unique_data1"}, {"part_type": "type1", "data": "unique_data2"}, {"part_type": "type2", "data": "data2"}]');

SELECT verify_request_inserted('hash3', '[{"data": "unique_data2", "frequency": 1, "part_type": "type1"}, {"data": "unique_data1", "frequency": 1, "part_type": "type1"}, {"data": "data2", "frequency": 4, "part_type": "type2"}]'::jsonb);
