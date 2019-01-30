# frozen_string_literal: true

require 'net/http'
require 'json'
require 'base64'

module KingslyCertbot
  class KingslyClient
    def self.get_cert_bundle(kingsly_server_host:,
                             kingsly_server_user:,
                             kingsly_server_password:,
                             top_level_domain:,
                             sub_domain:,
                             kingsly_http_read_timeout: 120,
                             kingsly_http_open_timeout: 5)

      body = {
        'top_level_domain' => top_level_domain,
        'sub_domain' => sub_domain
      }
      uri = URI.parse("http://#{kingsly_server_host}/v1/cert_bundles")

      http = Net::HTTP.new(uri.host, '80')

      http.read_timeout = kingsly_http_read_timeout
      http.open_timeout = kingsly_http_open_timeout

      headers = {}
      headers['Authorization'] = 'Basic ' + Base64.encode64("#{kingsly_server_user}:#{kingsly_server_password}").chop
      headers['Content-Type'] = 'application/json'

      resp = http.start do |http_request|
        http_request.post(uri.path, JSON.dump(body), headers)
      end

      raise 'Authentication failure with kingsly, Please check your authentication configuration' if resp.code == '401'

      body = JSON.parse(resp.body)
      CertBundle.new(top_level_domain, sub_domain, body['private_key'], body['full_chain'])
    end
  end
end
