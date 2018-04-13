# Getting started

## Prerequisites
- a Redis instance is required. This is used by the job queue engine. Define the connection url in an environment variable.
- a MySQL database in production. SQLlite is typically used in development and test.
- a Transloadit account. This service is used to process and transcode uploaded media
- an AWS S3 account and bucket. This stores user uploaded content.
- An empty pid file for sidekiq in `./tmp/pids/sidekiq.pid`

## Start Up
The startup procedure is defined in `Procfile` and consists of the following:
- web: startup the main api service
- worker: start the job queue engine, sidekiq. This handles things like sending emails, and processing uploads
- health_check: starts up a simple rack application that responds to requests with a simple 200 response.

To start the application run:

```
foreman start --formation web=1,worker=1
```
You can modify the number of processes dedicated to each process type with web=<number>,worker=<number>

If you prefer more fine grained instruction:

Startup the web server:
```bash
bundle exec thin start --port #{ENV['PORT'] || 8080} --environment production
```

Start sidekiq:
```bash
bundle exec sidekiq -C config/sidekiq.yml -e production
```

Run healthcheck process:
```bash
bundle exec rackup --port 8081 health_check.ru
```

# Run Tests
```bash
bundle exec rake
```

# Linting
Install rubocop if you havent done so already:
```bash
gem install rubocop
```
Then run from root project directory:
```bash
rubocop
```

# Environment Variables
These are the required environment variables that must be set in order to run all aspects of the application

```text
export SECRET_KEY_BASE="xxx"
export S3_BASE_URL="https://s3.amazonaws.com"
export S3_BUCKET="some-bucket"
export ASSET_HOST="https://cdn.xylophonexyz.com/"
export AWS_ACCESS_KEY_ID="xxx"
export AWS_SECRET_ACCESS_KEY="xxx+xxx"
export AWS_REGION="us-west-1"
export XYZ_DB_PASSWORD="xxx"
export XYZ_DB_HOST="10.1.1.1"
export SU_SCOPE="xxx"
export TRANSLOADIT_KEY="xxx"
export TRANSLOADIT_SECRET="xxx"
export REDIS_HOST="127.0.0.1"
export REDIS_URL="redis://127.0.0.1:6379"
export REDIS_PASSWORD=""
export MEMCACHED_URL="xxx"
export MAILGUN_DOMAIN="sandbox0cd080f6b6ac44818c1e2ec372b0d5bb.mailgun.org"
export MAILGUN_KEY="key-xxx"
export XYZ_GATEWAY_URL="http://localhost:8080"
export HOST_URL="http://localhost:3000"
export STRIPE_KEY="xxx"
export STRIPE_SECRET="xxx"
export XYZ_BASE_PLAN_ID="xxx"
export XYZ_PAGE_PLAN_ID="xxx"
export XYZ_DATA_PLAN_ID="xxx"
```

# Encrypting Environment Variables for Travis Deployment
Install travis command line tool:
```
gem install travis
```
The files that need to be encrypted are the following:
- xyz-db-1.ca.pem
- xyz-db-1.client.key.pem
- xyz-db-1.client.pem
- xyz-api.xylophonexyz.com.crt
- gae-client-secret.json
- .env.production 
- .env.test

Package important files:
```
tar -czf .deploy-client-credentials.tar.gz xyz-db-1.ca.pem xyz-db-1.client.key.pem xyz-db-1.client.pem xyz-api.xylophonexyz.com.crt xyz-api.xylophonexyz.com.key gae-client-secret.json .env.production .env.test
```

Encrypt:
```
travis encrypt-file .deploy-client-credentials.tar.gz --add
```

Decrypt:
```
# openssl aes-256-cbc -K $encrypted_59bb9ead7263_key -iv $encrypted_59bb9ead7263_iv
    -in .deploy-client-credentials.tar.gz.enc -out .deploy-client-credentials.tar.gz
    -d
```

Unpackage:
```
tar -xzf .deploy-client-credentials.tar.gz
```

These steps are conducted by travis and are defined in the .travis.yml, but this may be useful to look at when
re-encrypting or changing out files.

# Troubleshooting Tips
- The login mailer is sending login emails to the wrong user?
Make sure sidekiq is started in production mode if running in a production environment

# SSL Certificates
- The SSL certificates received must all be concatenated into one file.
- For example, when receiving ssl cert through comodo:
    - take the ca-bundle file and concatanate with crt file
    - take the certificate text from email and append to beginning of concatanated file
- This gives the full authority chain for the certificate