web: bundle exec rake deploy
worker: bundle exec rake sidekiq:start --trace
health_check: bundle exec rackup --port 8080 health_check.ru