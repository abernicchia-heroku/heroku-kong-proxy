# Kong API Gateway on Heroku

This repository contains a Kong API Gateway configured to run on Heroku. Kong is a popular, open-source API Gateway that helps you manage, secure, and monitor your APIs.

## Prerequisites

- [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli)
- [Git](https://git-scm.com/downloads)
- Heroku account with access to:
  - Container Registry
  - Postgres database addon

## Quick Deploy

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

## Manual Deployment Steps

1. Clone this repository:
   ```bash
   git clone https://github.com/abernicchia-heroku/heroku-kong-proxy.git
   cd heroku-kong-proxy
   ```

2. Create a new Heroku app:
   ```bash
   heroku create your-app-name
   ```

3. Add PostgreSQL addon:
   ```bash
   heroku addons:create heroku-postgresql:mini
   ```

4. Set the stack to container:
   ```bash
   heroku stack:set container
   ```

5. Deploy the application:
   ```bash
   git push heroku main
   ```

The deployment process is managed by `heroku.yml`, which defines how to build and run the container. Heroku will automatically:
- Build the Docker image using the Dockerfile
- Set the required environment variables
- Deploy the container
- Connect it to the PostgreSQL database

## Configuration

The Kong API Gateway is configured using the following files:

- `kong.conf`: Main Kong configuration file
- `kong.yml`: Declarative configuration file for services and routes
- `Dockerfile`: Container configuration with PostgreSQL support
- `heroku.yml`: Heroku container build and runtime configuration

### Environment Variables

The following environment variables are automatically configured:

- `DATABASE_URL`: Set automatically by Heroku PostgreSQL addon
- `PORT`: Set automatically by Heroku

Additional Kong-specific variables set in heroku.yml:
- `KONG_DATABASE`: postgres
- `KONG_PG_SSL`: on
- `KONG_PG_SSL_VERIFY`: off
- `KONG_PROXY_ACCESS_LOG`: /dev/stdout
- `KONG_ADMIN_ACCESS_LOG`: /dev/stdout
- `KONG_PROXY_ERROR_LOG`: /dev/stderr
- `KONG_ADMIN_ERROR_LOG`: /dev/stderr
- `KONG_ADMIN_LISTEN`: off (for security in Heroku environment)

## Monitoring and Logs

View your app's logs:
```bash
heroku logs --tail
```

## Scaling

Scale your Kong instance:
```bash
heroku ps:scale web=2
```

## Security Considerations

- Admin API is disabled by default for security
- SSL is enabled for PostgreSQL connections
- SSL verification is disabled to work with Heroku's PostgreSQL certificates

## Troubleshooting

1. If the app fails to start, check the logs:
   ```bash
   heroku logs --tail
   ```

2. Verify PostgreSQL connection:
   ```bash
   heroku pg:info
   ```

3. Restart the application:
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
