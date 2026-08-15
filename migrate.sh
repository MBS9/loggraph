echo "Applying migration: $5"
PGPASSWORD=$db_password psql -h $1 -p $2 -U $3 $4 -f "$5"
