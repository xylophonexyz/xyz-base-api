task :deploy do
  system("bundle exec rails server --port #{ENV.fetch('PORT') || 8080} --environment production")
end
