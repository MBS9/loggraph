--- Ensure db is empty before running this test. ---
TRUNCATE TABLE request_parts CASCADE;
TRUNCATE TABLE requests CASCADE;
TRUNCATE TABLE request_to_parts CASCADE;
--- Yayy!! Now its empty. ---

--- Ensure all the needed request parts exist in the part_types table ---
INSERT INTO part_types (name, description) VALUES ('type1', 'description1'),
('type2', 'description2'),
('type3', 'description3'),
('type4', 'description4'),
('type5', 'description5'),
('type6', 'description6'),
('type7', 'description7'),
('type8', 'description8'),
('type9', 'description9'),
('type10', 'description10')
ON CONFLICT (name) DO NOTHING;
