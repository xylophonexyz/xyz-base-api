namespace :sidekiq do
  desc 'start sidekiq'
  task :start do
    system('bundle exec sidekiq -C config/sidekiq.yml -e production')
  end

  desc 'stop sidekiq'
  task :stop do
    system('sidekiqctl stop sidekiq.pid 60')
  end
end
