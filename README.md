# Kong API Gateway on Heroku

This repository contains a Dockerized Kong API Gateway configured to run on Heroku. Kong is a popular, open-source API Gateway that helps you manage, secure, and monitor your APIs.

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
   heroku run -a your-app-name \
     -e KONG_DATABASE=postgres \
     -e KONG_PG_SSL=on \
     -e KONG_PG_SSL_VERIFY=off \
     bash
   ```

3. Once inside the dyno's shell, parse the database URL and set up Kong environment variables:
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

4. Finally, run the migrations:
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
