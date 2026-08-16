echo "Starting database migrations..."
for entry in $(ls "migrations"/*.sql | sort -t '.' -k 2,2V); do
  db_password=password ./migrate.sh $1 $2 $3 $4 $entry
done
