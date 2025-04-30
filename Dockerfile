FROM kong:3.5

# Create directory for declarative config
RUN mkdir -p /usr/local/kong/declarative

# Copy configuration files
COPY kong.conf /etc/kong/kong.conf
COPY kong.yml /usr/local/kong/declarative/kong.yml

# Create bootstrap script for Heroku configuration
USER root
RUN echo '#!/bin/sh\n\
set -e\n\
\n\
parse_database_url() {\n\
    echo "Parsing DATABASE_URL: $DATABASE_URL"\n\
    # Extract each component using cut and sed\n\
    userpass=$(echo "$DATABASE_URL" | sed -e "s|postgres://\\([^@]*\\)@.*|\\1|")\n\
    hostport=$(echo "$DATABASE_URL" | sed -e "s|postgres://[^@]*@\\([^/]*\\)/.*|\\1|")\n\
    dbname=$(echo "$DATABASE_URL" | sed -e "s|postgres://[^@]*@[^/]*/\\(.*\\)|\\1|")\n\
    \n\
    # Split userpass into username and password\n\
    export KONG_PG_USER=$(echo "$userpass" | cut -d: -f1)\n\
    export KONG_PG_PASSWORD=$(echo "$userpass" | cut -d: -f2)\n\
    \n\
    # Split hostport into host and port\n\
    export KONG_PG_HOST=$(echo "$hostport" | cut -d: -f1)\n\
    export KONG_PG_PORT=$(echo "$hostport" | cut -d: -f2)\n\
    \n\
    # Set database name\n\
    export KONG_PG_DATABASE="$dbname"\n\
    \n\
    # Debug output\n\
    echo "Parsed database configuration:"\n\
    echo "KONG_PG_USER=$KONG_PG_USER"\n\
    echo "KONG_PG_PASSWORD=<redacted>"\n\
    echo "KONG_PG_HOST=$KONG_PG_HOST"\n\
    echo "KONG_PG_PORT=$KONG_PG_PORT"\n\
    echo "KONG_PG_DATABASE=$KONG_PG_DATABASE"\n\
}\n\
\n\
if [ "$1" = "kong" ]; then\n\
    if [ -n "$DATABASE_URL" ]; then\n\
        echo "DATABASE_URL is set, attempting to parse..."\n\
        parse_database_url\n\
        \n\
        # Verify all required variables are set\n\
        if [ -z "$KONG_PG_USER" ] || [ -z "$KONG_PG_PASSWORD" ] || \n\
           [ -z "$KONG_PG_HOST" ] || [ -z "$KONG_PG_PORT" ] || \n\
           [ -z "$KONG_PG_DATABASE" ]; then\n\
            echo "Error: Failed to parse one or more database connection parameters"\n\
            echo "Please ensure DATABASE_URL is in the format: postgres://user:password@host:port/dbname"\n\
            exit 1\n\
        fi\n\
        \n\
        # Ensure PORT is set and configure proxy listening\n\
        if [ -z "$PORT" ]; then\n\
            echo "Error: PORT environment variable is not set"\n\
            exit 1\n\
        fi\n\
        export KONG_PROXY_LISTEN="0.0.0.0:$PORT"\n\
        echo "Configured Kong to listen on: $KONG_PROXY_LISTEN"\n\
        \n\
        echo "Successfully configured Kong database connection"\n\
    else\n\
        echo "Error: DATABASE_URL not set"\n\
        exit 1\n\
    fi\n\
fi\n\
\n\
# Execute the original entrypoint script\n\
exec /docker-entrypoint.sh "$@"' > /kong-heroku-bootstrap.sh && chmod +x /kong-heroku-bootstrap.sh

# Set environment variables
ENV KONG_DATABASE=postgres \
    KONG_PG_SSL=on \
    KONG_PG_SSL_VERIFY=off \
    KONG_PROXY_ACCESS_LOG=/dev/stdout \
    KONG_ADMIN_ACCESS_LOG=/dev/stdout \
    KONG_PROXY_ERROR_LOG=/dev/stderr \
    KONG_ADMIN_ERROR_LOG=/dev/stderr \
    KONG_ADMIN_LISTEN=off \
    PORT=8000

# Expose port (default, will be overridden by Heroku)
EXPOSE ${PORT}

# Use our bootstrap script as entrypoint
ENTRYPOINT ["/kong-heroku-bootstrap.sh"]

# Start kong
CMD ["kong", "docker-start"] 