./tests/run_sql.sh tests/cleardb.sql

curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -d @tests/graph.test.json \
    http://localhost:3000/rpc/insert_requests

curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $JWT_TOKEN" \
    http://localhost:3000/rpc/refresh_graph_view

## Set output content in var

JQ_FILTER=' 
  map({
    request_1: (if (.request_1 | tonumber) < (.request_2 | tonumber) then .request_1 else .request_2 end),
    request_2: (if (.request_1 | tonumber) < (.request_2 | tonumber) then .request_2 else .request_1 end),
    jaccard_index: .jaccard_index
  }) | sort_by(.request_1, .request_2)'

GRAPH_VIEW=$(curl http://localhost:3000/graph_view | jq "$JQ_FILTER")

EXPECTED=$(cat tests/graph.expected.json | jq .)

if [ "$GRAPH_VIEW" != "$EXPECTED" ]; then
    echo "Graph view does not match expected output"
    echo "Expected:"
    echo "$EXPECTED"
    echo "Actual:"
    echo "$GRAPH_VIEW"
    exit 1
fi
