require 'spec_helper'

RSpec.describe KingslyCertbot::KingslyClient do
  let(:top_level_domain) { 'golabs.io' }
  let(:sub_domain) { 'sample-integration-cert' }

  before :all do
    KingslyCertbot.configure do |config|
      config.kingsly_host     = 'kingsly.something.com'
      config.kingsly_user     = 'user'
      config.kingsly_password = 'pass'
    end
  end

  it 'kingsly client should return cert bundle' do
    stub_request(:post, 'http://kingsly.something.com/v1/cert_bundles')
      .with(
        body: '{"top_level_domain":"golabs.io","sub_domain":"sample-integration-cert"}',
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => 'Basic dXNlcjpwYXNz',
          'Content-Type' => 'application/json',
          'User-Agent' => 'Ruby'
        }
      )
      .to_return(
        status: 200,
        body: '{"private_key":"test_private_key", "full_chain":"test_full_chain"}',
        headers: {}
      )

    cert_bundle = KingslyCertbot::KingslyClient.get_cert_bundle(
      top_level_domain,
      sub_domain
    )

    expected_cert_bundle = KingslyCertbot::CertBundle.new('golabs.io', 'sample-integration-cert', 'test_private_key', 'test_full_chain')

    expect(cert_bundle).to eq(expected_cert_bundle)
  end

  it 'returns exception if the authorisation headers are not valid' do
    stub_request(:post, "http://kingsly.something.com/v1/cert_bundles").
        with(
          body: "{\"top_level_domain\":\"golabs.io\",\"sub_domain\":\"sample-integration-cert\"}",
          headers: {
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'Authorization' => 'Basic dXNlcjpwYXNz',
              'Content-Type' => 'application/json',
              'User-Agent' => 'Ruby'
          }).
        to_return(status: 401, body: "", headers: {})

    expect{KingslyCertbot::KingslyClient.get_cert_bundle(top_level_domain, sub_domain)}.to raise_error(RuntimeError,
    'Authentication failure with kingsly, Please check your authentication configuration')
  end

  it 'raises timeout exception when the http_read_timeout exceeds' do
    stub_request(:post, "http://kingsly.something.com/v1/cert_bundles").to_timeout

    expect{KingslyCertbot::KingslyClient.get_cert_bundle(top_level_domain, sub_domain)}.to raise_error(RuntimeError,
                                                                                                       'execution expired')
  end
end
