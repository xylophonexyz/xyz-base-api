namespace :cleanup do

  desc 'clean up files cached by carrierwave'
  task :cache do
    p CarrierWave
    CarrierWave.clean_cached_files!
  end

end
