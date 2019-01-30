# frozen_string_literal: true

module KingslyCertbot
  class Configuration
    attr_accessor :kingsly_host, :kingsly_user, :kingsly_password, :top_level_domain, :sub_domain,
                  :kingsly_http_read_timeout, :kingsly_http_open_timeout, :sentry_dsn, :environment

    def initialize(params = {})
      @kingsly_http_read_timeout = 120
      @kingsly_http_open_timeout = 5
      @sentry_dsn = params['SENTRY_DSN']
      @environment = params['ENVIRONMENT'] || 'development'
      @top_level_domain = params['TOP_LEVEL_DOMAIN']
      @sub_domain = params['SUB_DOMAIN']
      @kingsly_host = params['KINGSLY_SERVER_HOST']
      @kingsly_user = params['KINGSLY_SERVER_USER']
      @kingsly_password = params['KINGSLY_SERVER_PASSWORD']
    end
  end
end
