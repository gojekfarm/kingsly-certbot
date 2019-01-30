# frozen_string_literal: true

module KingslyCertbot
  class Runner
    attr_reader :configuration

    def initialize(args)
      raise 'Argument passed is not of type Array' if args.class != Array
      raise "Unknown argument '#{args[0]}'" if args[0] != '--config'
      raise "Config file does not exist at '#{args[1]}'" unless File.exist?(args[1])

      @config_path = args[1]
    end

    def configure
      begin
        local_config = YAML.load_file(@config_path)
      rescue Psych::SyntaxError => e
        raise StandardError, "Invalid YAML config file '#{@config_path}', original message: '#{e.message}'"
      end

      @configuration = KingslyCertbot::Configuration.new(local_config)
      @logger = Logger.new(STDOUT)
      Raven.configure do |config|
        config.dsn = @configuration.sentry_dsn
        config.encoding = 'json'
        config.environments = %w[production integration]
        config.current_environment = @configuration.environment
        config.logger = @logger
        config.release = KingslyCertbot::VERSION
      end
      self
    end

    def execute
      @configuration.validate!
      cert_bundle = KingslyClient.get_cert_bundle(
        kingsly_server_host: @configuration.kingsly_server_host,
        kingsly_server_user: @configuration.kingsly_server_user,
        kingsly_server_password: @configuration.kingsly_server_password,
        top_level_domain: @configuration.top_level_domain,
        sub_domain: @configuration.sub_domain,
        kingsly_http_read_timeout: @configuration.kingsly_http_read_timeout,
        kingsly_http_open_timeout: @configuration.kingsly_http_open_timeout
      )
      adapter = case @configuration.server_type
                when 'ipsec'
                  IpSecCertAdapter.new(cert_bundle, '/')
                else
                  raise "Unsupported server type #{@configuration.server_type}"
                end
      adapter.update_assets
      adapter.restart_service
    rescue StandardError => e
      @logger.warn('FAILED - Kingsly Certbot execution failed for following reason:')
      @logger.warn(e.message)
      Raven.capture_exception(e, 'Failed in KingslyCertbot::Runner.execute operation')
    end
  end
end
