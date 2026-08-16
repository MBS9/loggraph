CREATE TABLE requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    part_count INT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    last_seen_at TIMESTAMP NOT NULL DEFAULT NOW(),
    hash TEXT NOT NULL UNIQUE,
    frequency INT NOT NULL DEFAULT 1
);

CREATE OR REPLACE FUNCTION update_last_seen_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_seen_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_last_seen_at
AFTER UPDATE ON requests
FOR EACH ROW
EXECUTE FUNCTION update_last_seen_at();

CREATE TABLE part_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE request_parts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    part_type UUID NOT NULL REFERENCES part_types(id),
    data TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    frequency INT NOT NULL DEFAULT 1,
    unique (part_type, data)
);

CREATE TABLE request_to_parts (
    request_id UUID NOT NULL REFERENCES requests(id),
    part_id UUID NOT NULL REFERENCES request_parts(id),
    PRIMARY KEY (request_id, part_id)
);

CREATE INDEX idx_request_to_parts_part_id ON request_to_parts(part_id);
