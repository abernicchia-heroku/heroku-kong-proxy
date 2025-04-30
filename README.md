# Kong API Gateway on Heroku

This repository contains a Dockerized Kong API Gateway configured to run on Heroku. Kong is a popular, open-source API Gateway that helps you manage, secure, and monitor your APIs.

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

## Prerequisites

- Heroku CLI installed
- Docker installed (for local development)
- A Heroku account
- PostgreSQL add-on attached to your Heroku app

## Deployment Steps

1. Create a new Heroku app:
   ```bash
   heroku create your-app-name
   ```

2. Add PostgreSQL add-on:
   ```bash
   heroku addons:create heroku-postgresql:mini
   ```

3. Deploy the application:
   ```bash
   git push heroku main
   ```

## Database Setup

Before Kong can start serving requests, you need to initialize its database schema. This is a one-time operation that should be performed after the first deployment or when upgrading Kong to a new version.

To run the database migrations, you'll need to execute them in a one-off dyno with the proper database configuration. Here's how:

1. First, get your database URL:
   ```bash
   heroku config:get DATABASE_URL -a your-app-name
   ```

2. Run a one-off dyno with the necessary Kong environment variables:
   ```bash
   heroku run bahs -a your-app-name
   ```

3. Finally, run the migrations:
   ```bash
   kong migrations bootstrap --force
   ```

This command will:
- Create the necessary database tables
- Initialize the schema
- Prepare the database for Kong operations

The `--force` flag ensures the operation completes even if the database was partially initialized.

## Verification

After running the migrations, you can verify that Kong is running properly by checking the logs:

```bash
heroku logs --tail
```

You should see messages indicating that Kong has started successfully and is listening for requests.

## Configuration

The Kong gateway is configured using the following files:
- `kong.conf`: Main configuration file
- `kong.yml`: Declarative configuration for routes and services
- `Dockerfile`: Container configuration and bootstrap script

Environment variables are automatically configured by the bootstrap script using the `DATABASE_URL` provided by Heroku.

## Troubleshooting

If you encounter any issues:

1. Check the logs:
   ```bash
   heroku logs --tail
   ```

2. Verify the database connection:
   ```bash
   heroku config | grep DATABASE_URL
   ```

3. If needed, you can restart the application:
   ```bash
   heroku restart
   ```

## Local Development

To build and run the container locally:

1. Build the image:
   ```bash
   docker build -t kong-heroku .
   ```

2. Run the container:
   ```bash
   docker run -p 8000:8000 -e DATABASE_URL=your_postgres_url kong-heroku
   ```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions, please open an issue in the GitHub repository.

## Managing Kong Configuration with decK

[decK](https://docs.konghq.com/deck/) is Kong's official configuration management tool. It allows you to manage Kong's configuration as code and sync it with your Kong instance.

### Prerequisites

1. Install decK:
   ```bash
   # macOS
   brew install kong/deck/deck

   # Linux
   curl -sL https://github.com/kong/deck/releases/latest/download/deck_$(uname -s)_amd64.tar.gz | tar xz -C /tmp/
   sudo mv /tmp/deck /usr/local/bin/
   ```

### Initial Setup

1. Create a temporary Admin API endpoint using a one-off dyno:
   ```bash
   heroku run -a your-app-name \
     -e KONG_DATABASE=postgres \
     -e KONG_PG_SSL=on \
     -e KONG_PG_SSL_VERIFY=off \
     -e KONG_ADMIN_LISTEN=0.0.0.0:8001 \
     -p 8001 \
     bash
   ```

2. In the dyno shell, parse the database URL and set up Kong environment variables:
   ```bash
   # Get DATABASE_URL from the environment
   DATABASE_URL=$(echo $DATABASE_URL)
   
   # Parse DATABASE_URL components
   userpass=$(echo "$DATABASE_URL" | sed -e "s|postgres://\([^@]*\)@.*|\1|")
   hostport=$(echo "$DATABASE_URL" | sed -e "s|postgres://[^@]*@\([^/]*\)/.*|\1|")
   dbname=$(echo "$DATABASE_URL" | sed -e "s|postgres://[^@]*@[^/]*/\(.*\)|\1|")
   
   # Set Kong environment variables
   export KONG_PG_USER=$(echo "$userpass" | cut -d: -f1)
   export KONG_PG_PASSWORD=$(echo "$userpass" | cut -d: -f2)
   export KONG_PG_HOST=$(echo "$hostport" | cut -d: -f1)
   export KONG_PG_PORT=$(echo "$hostport" | cut -d: -f2)
   export KONG_PG_DATABASE="$dbname"
   ```

3. Start Kong with Admin API enabled:
   ```bash
   kong start
   ```

4. In a new terminal, create a configuration file:
   ```bash
   # Get the dyno's URL (replace your-app-name)
   KONG_ADDR=$(heroku run:status -a your-app-name | grep 'web.' | awk '{print $3}')
   
   # Export current configuration
   deck dump --kong-addr http://$KONG_ADDR:8001 --output-file kong.yaml
   ```

### Managing Configuration

1. Edit `kong.yaml` to define your services, routes, plugins, and other Kong entities:
   ```yaml
   _format_version: "3.0"
   services:
     - name: example-service
       url: http://example.com
       routes:
         - name: example-route
           paths:
             - /example
       plugins:
         - name: rate-limiting
           config:
             minute: 5
   ```

2. Validate your configuration:
   ```bash
   deck validate -s kong.yaml
   ```

3. Diff changes before applying:
   ```bash
   deck diff --kong-addr http://$KONG_ADDR:8001 -s kong.yaml
   ```

4. Apply the configuration:
   ```bash
   deck sync --kong-addr http://$KONG_ADDR:8001 -s kong.yaml
   ```

### Best Practices

1. Version Control:
   - Keep your `kong.yaml` in version control
   - Review changes through pull requests
   - Use CI/CD to validate configuration files

2. Environment Management:
   - Use separate configuration files for different environments
   - Use decK's `--select-tag` to manage environment-specific configurations

3. Security:
   - Never commit sensitive values (use environment variables)
   - Limit Admin API access to trusted networks
   - Always run Admin API in one-off dynos, never in production

4. Backup:
   - Regularly export your configuration using `deck dump`
   - Store backups in a secure location

### Troubleshooting

If you encounter issues:

1. Verify connectivity:
   ```bash
   curl http://$KONG_ADDR:8001/status
   ```

2. Check decK version compatibility:
   ```bash
   deck version
   ```

3. Enable verbose logging:
   ```bash
   deck sync --kong-addr http://$KONG_ADDR:8001 -s kong.yaml --verbose
   ```
