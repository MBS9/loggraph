for test_file in tests/*.sql; do
  echo "Running test: $test_file"
  PGPASSWORD=password psql -h localhost -p 5432 -U postgres -d database -f "$test_file" || { echo "Test failed: $test_file"; exit 1; }
done
