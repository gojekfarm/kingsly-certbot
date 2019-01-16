module KingslyCertbot
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration = self.configuration ||  Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :kingsly_host

    def initialize
    end
  end
end
