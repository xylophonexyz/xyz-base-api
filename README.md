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