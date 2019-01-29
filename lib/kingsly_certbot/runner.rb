# frozen_string_literal: true

module KingslyCertbot
  class Runner
    def initialize(args)
      raise 'Argument passed is not of type Array' if args.class != Array
      raise "Unknown argument '#{args[0]}'" if args[0] != '--config'
      raise "Config file does not exist at '#{args[1]}'" unless File.exist?(args[1])

      @config_path = args[1]
    end

    def configure
      local_config = YAML.load_file(@config_path)
      environment = local_config['ENVIRONMENT'] || 'development'
      sentry_dsn = local_config['SENTRY_DSN']
      KingslyCertbot.configure do |config|
        config.sentry_dsn = sentry_dsn
      end

      Raven.configure do |config|
        config.dsn = KingslyCertbot.configuration.sentry_dsn
        config.encoding = 'json'
        config.environments = %w[production integration]
        config.current_environment = environment
        config.logger = Raven::Logger.new(STDOUT)
        config.release = KingslyCertbot::VERSION
      end
      self
    rescue Psych::SyntaxError => e
      raise StandardError, "Invalid YAML config file '#{@config_path}', original message: '#{e.message}'"
    end
  end
end
