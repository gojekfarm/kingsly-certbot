# frozen_string_literal: true

module KingslyCertbot
  class Configuration
    attr_accessor :kingsly_server_host, :kingsly_server_user, :kingsly_server_password, :top_level_domain, :sub_domain,
                  :kingsly_http_read_timeout, :kingsly_http_open_timeout, :sentry_dsn, :environment

    def initialize(params = {})
      @kingsly_http_read_timeout = 120
      @kingsly_http_open_timeout = 5
      @sentry_dsn = params['SENTRY_DSN']
      @environment = params['ENVIRONMENT'] || 'development'
      @top_level_domain = params['TOP_LEVEL_DOMAIN']
      @sub_domain = params['SUB_DOMAIN']
      @kingsly_server_host = params['KINGSLY_SERVER_HOST']
      @kingsly_server_user = params['KINGSLY_SERVER_USER']
      @kingsly_server_password = params['KINGSLY_SERVER_PASSWORD']
    end

    def validate!
      %i[top_level_domain sub_domain kingsly_server_host kingsly_server_user kingsly_server_password].each do |mandatory|
        raise "Missing mandatory config '#{mandatory}'" if send(mandatory).nil? || send(mandatory) == ''
      end
      self
    end
  end
end
