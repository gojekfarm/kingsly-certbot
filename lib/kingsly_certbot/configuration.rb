# frozen_string_literal: true

module KingslyCertbot
  class Configuration
    VARS = %i[kingsly_server_host kingsly_server_port top_level_domain sub_domain
              kingsly_http_read_timeout kingsly_http_open_timeout sentry_dsn environment server_type ipsec_root].freeze
    attr_accessor(*VARS)

    def initialize(params = {})
      @kingsly_http_read_timeout = 300
      @kingsly_http_open_timeout = 20
      @sentry_dsn = params['SENTRY_DSN']
      @environment = params['ENVIRONMENT'] || 'development'
      @top_level_domain = params['TOP_LEVEL_DOMAIN']
      @sub_domain = params['SUB_DOMAIN']
      @kingsly_server_host = params['KINGSLY_SERVER_HOST']
      @kingsly_server_port = params['KINGSLY_SERVER_PORT']
      @server_type = params['SERVER_TYPE']
      @ipsec_root = params['IPSEC_ROOT'] || '/'
    end

    def validate!
      %i[top_level_domain sub_domain kingsly_server_host kingsly_server_port server_type].each do |mandatory|
        raise "Missing mandatory config '#{mandatory}'" if send(mandatory).nil? || send(mandatory) == ''
      end
      raise "Unsupported server_type '#{server_type}'" unless ['ipsec'].include?(server_type)

      self
    end
  end
end
