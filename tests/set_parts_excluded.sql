UPDATE request_parts
SET excluded = TRUE
WHERE data IN ('type1 content', 'type2 content');
