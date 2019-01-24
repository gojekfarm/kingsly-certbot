# frozen_string_literal: true

require 'fileutils'

module KingslyCertbot
  class CertBundle
    attr_reader :tld, :subdomain, :private_key, :full_chain

    def initialize(tld, subdomain, private_key, full_chain)
      @tld = tld
      @subdomain = subdomain
      @private_key = private_key
      @full_chain = full_chain
    end

    def ==(other)
      return false if other.class != self.class

      state == other.state
    end

    def hash
      state.hash
    end

    protected

    def state
      [tld, subdomain, private_key, full_chain]
    end
  end
end
