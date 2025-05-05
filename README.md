# Kong API Gateway on Heroku

This repository contains a Dockerized Kong API Gateway configured to run on Heroku. Kong is a popular, open-source API Gateway that helps you manage, secure, and monitor your APIs.

## Disclaimer

The author of this article makes any warranties about the completeness, reliability and accuracy of this information. **Any action you take upon the information of this website is strictly at your own risk**, and the author will not be liable for any losses and damages in connection with the use of the website and the information provided. **None of the items included in this repository form a part of the Heroku Services.**

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

## Prerequisites

- A Heroku account
- Heroku CLI installed
- Kong Admin API deployed as Heroku app (see https://github.com/abernicchia-heroku/heroku-kong-admin)
- Kong Admin API's PostgreSQL add-on attached to your Heroku app
- Docker installed (for local development)

## Deployment Steps

1. Create a new Heroku app:
   ```bash
   heroku create your-app-name
   ```

2. Attach Kong Admin API's PostgreSQL add-on as DATABASE_URL:
   ```bash
   heroku addons:attach kong-admin-api-app-posrtgres-addon-name -a your-app-name
   ```

3. Deploy the application:
   ```bash
   git push heroku main
   ```


## Verification

You can verify that Kong is running properly by checking the logs:

```bash
heroku logs --tail
```

You should see messages indicating that Kong has started successfully and is listening for requests.

## Configuration

The Kong gateway is configured using the following files:
- `kong.conf`: Main configuration file
- `kong.yml.sample`: Sample of declarative configuration for routes and services
- `Dockerfile`: Container configuration and bootstrap script

Environment variables are automatically configured by the bootstrap script using the `DATABASE_URL` provided by Heroku.

## ⚠️ Security Notice

**This implementation does NOT provide a secured Kong Proxy**

- There is no enforced HTTPS/SSL for the Kong Proxy.
- No authentication or RBAC is enabled by default.
- The Proxy is accessible to anyone who knows the URL.

**Do NOT use this setup in production or for sensitive workloads without adding proper security controls (HTTPS, firewall, authentication, etc.).**

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

## Support

For issues and questions, please open an issue in the GitHub repository.
