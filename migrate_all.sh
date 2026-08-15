echo "Starting database migrations..."
read -p "Database password: " db_password
for entry in $(ls "migrations"/*.sql | sort -t '.' -k 2,2V); do
  db_password=$db_password ./migrate.sh $1 $2 $3 $4 $entry
done
