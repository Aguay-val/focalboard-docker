#!/bin/sh

# Function to generate a random salt (Maybe  useful in later release)
generate_salt() {
  tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 48 | head -n 1
}

# Read environment variables or set default values
DB_HOST=${DB_HOST:-db}
DB_PORT_NUMBER=${DB_PORT_NUMBER:-5432}
# see https://www.postgresql.org/docs/current/libpq-ssl.html
# for usage when database connection requires encryption
# filenames should be escaped if they contain spaces
#  i.e. $(printf %s ${MY_ENV_VAR:-''}  | jq -s -R -r @uri)
# the location of the CA file can be set using environment var PGSSLROOTCERT
# the location of the CRL file can be set using PGSSLCRL
# The URL syntax for connection string does not support the parameters
# sslrootcert and sslcrl reliably, so use these PostgreSQL-specified variables
# to set names if using a location other than default
DB_USE_SSL=${DB_USE_SSL:-disable}
FB_DBNAME=${FB_DBNAME:-focalboard}
FB_CONFIG=${FB_CONFIG:-/app/focalboard/config.json}

if [ "$1" = '/app/focalboard/bin/focalboard-server' ]; then

  if [ ! -f "$FB_CONFIG" ]; then
    # If there is no configuration file, create it with some default values
    echo "No configuration file $FB_CONFIG"
    echo "Creating a new one"
    # Copy default configuration file
    cp config.json.save "$FB_CONFIG"
    # Substitute some parameters with jq
    jq '.port = 8000' "$FB_CONFIG" >"$FB_CONFIG.tmp" && mv "$FB_CONFIG.tmp" "$FB_CONFIG"
    jq '.serverRoot = "http://localhost:8000"' "$FB_CONFIG" >"$FB_CONFIG.tmp" && mv "$FB_CONFIG.tmp" "$FB_CONFIG"
    jq '.dbtype = "sqlite3"' "$FB_CONFIG" >"$FB_CONFIG.tmp" && mv "$FB_CONFIG.tmp" "$FB_CONFIG"
    jq '.dbconfig = "./focalboard.db"' "$FB_CONFIG" >"$FB_CONFIG.tmp" && mv "$FB_CONFIG.tmp" "$FB_CONFIG"
    jq '.useSSL = false' "$FB_CONFIG" >"$FB_CONFIG.tmp" && mv "$FB_CONFIG.tmp" "$FB_CONFIG"
    jq '.webpath = "./pack"' "$FB_CONFIG" >"$FB_CONFIG.tmp" && mv "$FB_CONFIG.tmp" "$FB_CONFIG"
    jq '.filespath = "./files"' "$FB_CONFIG" >"$FB_CONFIG.tmp" && mv "$FB_CONFIG.tmp" "$FB_CONFIG"
    jq '.telemetry = true' "$FB_CONFIG" >"$FB_CONFIG.tmp" && mv "$FB_CONFIG.tmp" "$FB_CONFIG"
    jq '.session_expire_time = 2592000' "$FB_CONFIG" >"$FB_CONFIG.tmp" && mv "$FB_CONFIG.tmp" "$FB_CONFIG"
    jq '.session_refresh_time = 18000' "$FB_CONFIG" >"$FB_CONFIG.tmp" && mv "$FB_CONFIG.tmp" "$FB_CONFIG"
    jq '.localOnly = false' "$FB_CONFIG" >"$FB_CONFIG.tmp" && mv "$FB_CONFIG.tmp" "$FB_CONFIG"
    jq '.enableLocalMode = true' "$FB_CONFIG" >"$FB_CONFIG.tmp" && mv "$FB_CONFIG.tmp" "$FB_CONFIG"
    jq '.localModeSocketLocation = "/var/tmp/focalboard_local.socket"' "$FB_CONFIG" >"$FB_CONFIG.tmp" && mv "$FB_CONFIG.tmp" "$FB_CONFIG"
  else
    echo "Using existing config file $FB_CONFIG"
  fi

  # Configure database access
  if [ -n "$FB_USERNAME" ] && [ -n "$FB_PASSWORD" ]; then
    echo "Configure database connection..."
    # URLEncode the password, allowing for special characters
    ENCODED_PASSWORD=$(printf %s "$FB_PASSWORD" | jq -s -R -r @uri)
    jq '.dbtype = "postgres"' "$FB_CONFIG" >"$FB_CONFIG.tmp" && mv "$FB_CONFIG.tmp" "$FB_CONFIG"
    jq ".dbconfig =  \"postgres://$FB_USERNAME:$ENCODED_PASSWORD@$DB_HOST:$DB_PORT_NUMBER/$FB_DBNAME?sslmode=$DB_USE_SSL&connect_timeout=10\"" "$FB_CONFIG" >"$FB_CONFIG.tmp" && mv "$FB_CONFIG.tmp" "$FB_CONFIG"
    echo "OK"
  else
    echo "Using existing database connection"
  fi

  # Wait another second for the database to be properly started.
  # Necessary to avoid "panic: Failed to open sql connection pq: the database system is starting up"
  sleep 1

  echo "Starting focalboard"
fi

exec "$@"