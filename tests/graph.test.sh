set -e

./tests/run_sql.sh tests/cleardb.sql

PGPASSWORD=password psql -h localhost -U postgres database -c "UPDATE loggraph_config SET value = '0.0' WHERE key = 'min_jaccard_index';"

curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -d @tests/graph.test.json \
    http://localhost:3000/rpc/insert_requests

./tests/run_sql.sh tests/set_parts_excluded.sql

curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $JWT_TOKEN" \
    http://localhost:3000/rpc/refresh_graph_view

## Set output content in var

JQ_FILTER=' 
  map({
    jaccard_index: .jaccard_index
  }) | sort_by(.jaccard_index)'

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
