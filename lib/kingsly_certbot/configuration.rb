module KingslyCertbot
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration = self.configuration || Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :kingsly_host, :kingsly_user, :kingsly_password, :top_level_domain, :sub_domain,
                  :kingsly_http_read_timeout, :kingsly_http_open_timeout

    def initialize
      @kingsly_http_read_timeout = 120
      @kingsly_http_open_timeout = 5
    end
  end
end
