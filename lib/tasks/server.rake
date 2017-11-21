namespace :server do

  @PRODUCTION_PORTS = %w(443)
  @DEVELOPMENT_PORTS = %w(3000)

  desc 'start the server'
  task :start, [:env] do |t, args|
    env = args[:env] || 'development'

    if env == 'production'
      ports = @PRODUCTION_PORTS
      args = [
        { key: 'ssl', value: '' },
        { key: 'ssl-key-file', value: ENV.fetch('SSL_KEY_PATH') },
        { key: 'ssl-cert-file', value: ENV.fetch('SSL_CERT_PATH') },
        { key: 'pid', value: 'tmp/pids/thin.pid' },
        { key: 'daemon', value: '' },
        { key: 'servers', value: ports.length.to_s }
      ]
    else
      ports = @DEVELOPMENT_PORTS
    end

    args << { key: 'port', value: ports.first }
    args << { key: 'environment', value: env }
    args << { key: 'timeout', value: 60*5 }

    command = 'thin start '
    args.each do |arg|
      command += '--' + arg[:key]
      command += ' ' + arg[:value]
      command += ' '
    end
    system(command)
  end

  desc 'stop the server'
  task :stop, [:env] do |t, args|
    env = args[:env] || 'development'

    ports = @DEVELOPMENT_PORTS
    if env == 'production'
      ports = @PRODUCTION_PORTS
    end

    ports.each do |port|
      system('thin stop -o ' + port)
    end
  end
end
