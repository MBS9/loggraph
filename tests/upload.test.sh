./tests/run_sql.sh tests/cleardb.sql

echo "test" > test
echo "test2" > test
echo "{}" > test
echo "{\"path\": \"part1/part2/part3\"}" > test
echo "{\"path\": \"part1/part2/part3\", \"type1\": \"other_value\"}" > test
echo "{\"path\": \"part1/part2/\", \"type1\": \"other_value\", \"type2\": \"another_value\"}" > test


EXPECTED_REQUESTS=$(cat tests/requests_output.json | jq .)
EXPECTED_REQUEST_PARTS=$(cat tests/request_parts_output.json | jq .)

REQUESTS=''
REQUEST_PARTS=''

iteration=0

until [ "$REQUESTS" = "$EXPECTED_REQUESTS" ] && [ "$REQUEST_PARTS" = "$EXPECTED_REQUEST_PARTS" ]; do
    sleep 2
    if [ $iteration -ge 10 ]; then
        echo "Expected requests and request_parts not found after 10 iterations."
        echo "Expected requests: $EXPECTED_REQUESTS"
        echo "Actual requests: $REQUESTS"
        echo "Expected request_parts: $EXPECTED_REQUEST_PARTS"
        echo "Actual request_parts: $REQUEST_PARTS"
        exit 1
    fi
    iteration=$((iteration + 1))
    echo "Checking requests and request_parts..."
    REQUESTS=$(curl http://localhost:3000/requests | jq 'map({hash: .hash, part_count: .part_count, frequency: .frequency}) | sort_by(.hash)')
    REQUEST_PARTS=$(curl http://localhost:3000/request_parts | jq 'map({data: .data, frequency: .frequency}) | sort_by(.data)')
done
