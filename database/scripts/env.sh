# Shared config for database scripts. Values must match the `db` service in
# the root docker-compose.yml. Override any of these as env vars if you
# change the compose file.
DB_SERVICE="${DB_SERVICE:-db}"
DB_NAME="${DB_NAME:-smartstock}"
DB_ROOT_PASSWORD="${DB_ROOT_PASSWORD:-dev-only-change-me}"
