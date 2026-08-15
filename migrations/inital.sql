CREATE TABLE requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    part_count INT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE part_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT
);

INSERT INTO part_types (name, description) VALUES 
('method', 'HTTP Method (GET, POST, etc.)'),
('host', 'The host of the request'),
('query_part', 'Part of the query part of the URL'),
('endpoint_part', 'Part of the endpoint path of the URL');

CREATE TABLE request_parts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID NOT NULL REFERENCES requests(id),
    part_type UUID NOT NULL REFERENCES part_types(id),
    data TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    frequency INT NOT NULL DEFAULT 1
);

CREATE TABLE request_to_parts (
    request_id UUID NOT NULL REFERENCES requests(id),
    part_id UUID NOT NULL REFERENCES request_parts(id),
    PRIMARY KEY (request_id, part_id)
);
