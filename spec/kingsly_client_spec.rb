require 'spec_helper'

RSpec.describe KingslyCertbot::KingslyClient do
  let(:top_level_domain) { 'golabs.io' }
  let(:sub_domain) { 'sample-integration-cert' }
  let(:private_key) { "-----BEGIN RSA PRIVATE KEY-----\nFOO...\n-----END RSA PRIVATE KEY-----\n" }
  let(:full_chain) { "-----BEGIN CERTIFICATE-----\nBAR...\n-----END CERTIFICATE-----\n" }
  let(:kingsly_server_host) { 'localhost' }
  let(:kingsly_server_port) { 8080 }

  it 'kingsly client should return cert bundle' do
    stub_request(:post, "http://#{kingsly_server_host}:#{kingsly_server_port}/v1/cert_bundles")
      .with(
        body: %({"top_level_domain":"#{top_level_domain}","sub_domain":"#{sub_domain}"}),
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type' => 'application/json',
          'User-Agent' => 'Ruby'
        }
      )
      .to_return(
        status: 200,
        body: { private_key: private_key, full_chain: full_chain }.to_json,
        headers: {}
      )

    cert_bundle = KingslyCertbot::KingslyClient.get_cert_bundle(kingsly_server_host: kingsly_server_host,
                                                                kingsly_server_port: kingsly_server_port,
                                                                top_level_domain: top_level_domain,
                                                                sub_domain: sub_domain)

    expected_cert_bundle = KingslyCertbot::CertBundle.new(top_level_domain, sub_domain, private_key, full_chain)

    expect(cert_bundle).to eq(expected_cert_bundle)
  end

  it 'returns exception if the authorisation headers are not valid' do
    stub_request(:post, "http://#{kingsly_server_host}:#{kingsly_server_port}/v1/cert_bundles")
      .with(
        body: %({"top_level_domain":"#{top_level_domain}","sub_domain":"#{sub_domain}"}),
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type' => 'application/json',
          'User-Agent' => 'Ruby'
        }
      )
      .to_return(status: 401, body: '', headers: {})

    expect do
      KingslyCertbot::KingslyClient.get_cert_bundle(kingsly_server_host: kingsly_server_host,
                                                    kingsly_server_port: kingsly_server_port,
                                                    top_level_domain: top_level_domain,
                                                    sub_domain: sub_domain)
    end
      .to raise_error(RuntimeError,
                      'Authentication failure with kingsly, Please check your authentication configuration')
  end

  it 'raises timeout exception when the http_read_timeout exceeds' do
    stub_request(:post, "http://#{kingsly_server_host}:#{kingsly_server_port}/v1/cert_bundles").to_timeout

    expect do
      KingslyCertbot::KingslyClient.get_cert_bundle(kingsly_server_host: kingsly_server_host,
                                                    kingsly_server_port: kingsly_server_port,
                                                    top_level_domain: top_level_domain,
                                                    sub_domain: sub_domain)
    end
      .to raise_error(RuntimeError,
                      'execution expired')
  end
end
