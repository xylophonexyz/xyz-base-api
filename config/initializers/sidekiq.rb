# frozen_string_literal: true

Sidekiq.configure_server do |config|
  options = {
    url: ENV.fetch('REDIS_URL'),
    network_timeout: 5
  }
  unless ENV.fetch('REDIS_PASSWORD').empty?
    options[:password] = ENV.fetch('REDIS_PASSWORD')
  end
  config.redis = options
end

Sidekiq.configure_client do |config|
  options = {
    url: ENV.fetch('REDIS_URL'),
    network_timeout: 5
  }
  unless ENV.fetch('REDIS_PASSWORD').empty?
    options[:password] = ENV.fetch('REDIS_PASSWORD')
  end
  config.redis = options
end
