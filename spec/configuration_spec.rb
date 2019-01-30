require 'spec_helper'

RSpec.describe KingslyCertbot do
  let(:sentry_dsn) { 'https://foo:bar@sentry.com/0' }
  let(:environment) { 'test' }
  let(:tld) { 'example.com' }
  let(:sub_domain) { 'www' }
  let(:host) { 'certbot.com' }
  let(:user) { 'user' }
  let(:password) { 'password' }
  let(:server_type) { 'ipsec' }

  context 'initialize' do
    it 'should set properties from passed params' do
      configuration = KingslyCertbot::Configuration.new(
        'SENTRY_DSN' => sentry_dsn,
        'ENVIRONMENT' => environment,
        'TOP_LEVEL_DOMAIN' => tld,
        'SUB_DOMAIN' => sub_domain,
        'KINGSLY_SERVER_HOST' => host,
        'KINGSLY_SERVER_USER' => user,
        'KINGSLY_SERVER_PASSWORD' => password,
        'SERVER_TYPE' => server_type
      )
      expect(configuration.sentry_dsn).to eq(sentry_dsn)
      expect(configuration.environment).to eq(environment)
      expect(configuration.top_level_domain).to eq(tld)
      expect(configuration.sub_domain).to eq(sub_domain)
      expect(configuration.kingsly_server_host).to eq(host)
      expect(configuration.kingsly_server_user).to eq(user)
      expect(configuration.kingsly_server_password).to eq(password)
      expect(configuration.server_type).to eq(server_type)
    end
  end

  context 'validate' do
    let(:valid_config) do
      {
        'SENTRY_DSN' => sentry_dsn,
        'ENVIRONMENT' => environment,
        'TOP_LEVEL_DOMAIN' => tld,
        'SUB_DOMAIN' => sub_domain,
        'KINGSLY_SERVER_HOST' => host,
        'KINGSLY_SERVER_USER' => user,
        'KINGSLY_SERVER_PASSWORD' => password,
        'SERVER_TYPE' => server_type
      }
    end

    %w[TOP_LEVEL_DOMAIN SUB_DOMAIN KINGSLY_SERVER_HOST KINGSLY_SERVER_USER KINGSLY_SERVER_PASSWORD].each do |mandatory|
      it "should validate for missing mandatory property #{mandatory}" do
        valid_config.delete(mandatory)
        expect { KingslyCertbot::Configuration.new(valid_config).validate! }.to raise_exception("Missing mandatory config '#{mandatory.downcase}'")
      end
    end

    it 'should return config if valid' do
      config = KingslyCertbot::Configuration.new(valid_config)
      expect(config.validate!).to eq(config)
    end

    it 'should raise exception if server_type is not supported' do
      valid_config['SERVER_TYPE'] = 'invalid'
      config = KingslyCertbot::Configuration.new(valid_config)
      expect { config.validate! }.to raise_exception("Unsupported server_type 'invalid'")
    end
  end
end
