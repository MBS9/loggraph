for test_file in tests/*.test.sql; do
  echo "Running test: $test_file"
  PGPASSWORD=password psql -h localhost -p 5432 -U postgres -d database -f "$test_file" || { echo "Test failed: $test_file"; exit 1; }
done

for test_file in tests/*.test.sh; do
  echo "Running test: $test_file"
  JWT_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoibG9naW5zZXJ0ZXIifQ.9W8b7OpTmd_CNB05yM1Y9k_sQo_xwgSh60CUW-RRGSI" ./"$test_file" || { echo "Test failed: $test_file"; exit 1; }
done
