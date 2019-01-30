# frozen_string_literal: true

require 'spec_helper'

RSpec.describe KingslyCertbot::Runner do
  context 'initialize' do
    it 'should raise exception if the config parameter is invalid' do
      expect { KingslyCertbot::Runner.new(nil) }.to raise_exception('Argument passed is not of type Array')
      expect { KingslyCertbot::Runner.new('') }.to raise_exception('Argument passed is not of type Array')
      expect { KingslyCertbot::Runner.new('foo') }.to raise_error(RuntimeError, 'Argument passed is not of type Array')
      expect { KingslyCertbot::Runner.new(['--foo', 'bar']) }.to raise_error("Unknown argument '--foo'")
    end

    it 'should raise an exception if the given file path doesnt exist' do
      allow(File).to receive(:exist?).with('/foo/bar').and_return(false)
      expect { KingslyCertbot::Runner.new(['--config', '/foo/bar']) }.to raise_exception("Config file does not exist at '/foo/bar'")
    end
  end

  context 'load_config' do
    let(:tmp_dir) { Dir.mktmpdir }
    let(:conf_file) { "#{tmp_dir}/kingsly-certbot.conf" }

    before(:each) do
      Raven.instance.configuration = Raven::Configuration.new
      Raven.instance.configuration.silence_ready = true
    end

    it 'should load the config file from disk and raise an exception if config is invalid' do
      File.write(conf_file, <<~STR
        `invalid yaml file
      STR
    )
      certbot = KingslyCertbot::Runner.new(['--config', conf_file])
      expect { certbot.configure }.to raise_error(start_with("Invalid YAML config file '#{conf_file}'"))
    end

    it 'should load the config file from disk and set the configuration' do
      sentry_dsn = 'http://foo:bar@example.com/420'
      File.write(conf_file, <<~STR
        SENTRY_DSN: #{sentry_dsn}
      STR
    )
      certbot = KingslyCertbot::Runner.new(['--config', conf_file])
      certbot.configure
      expect(certbot.configuration.sentry_dsn).to eq(sentry_dsn)
    end

    it 'should not configure sentry if sentry_dsn variable not provided' do
      File.write(conf_file, <<~STR
        ENVIRONMENT: development
      STR
    )
      certbot = KingslyCertbot::Runner.new(['--config', conf_file])
      certbot.configure
      expect(Raven.configuration.server).to eq(nil)
    end
  end

  context 'execute' do
    let(:tmp_dir) { Dir.mktmpdir }
    let(:conf_file) { "#{tmp_dir}/kingsly-certbot.conf" }

    before(:each) do
      Raven.instance.configuration = Raven::Configuration.new
      Raven.instance.configuration.silence_ready = true
      allow_any_instance_of(Logger).to receive(:warn)
      File.write(conf_file, <<~STR
        SENTRY_DSN: http://foo:bar@example.com/42
        ENVIRONMENT: test
        TOP_LEVEL_DOMAIN: example.com
        SUB_DOMAIN: www
        KINGSLY_SERVER_HOST: kingsly-test.com
        KINGSLY_SERVER_USER: user
        KINGSLY_SERVER_PASSWORD: password
        SERVER_TYPE: ipsec
      STR
    )
    end

    it 'should catch configuration validate failure and log to raven' do
      error = StandardError.new('validation error in configuration')
      expect_any_instance_of(KingslyCertbot::Configuration).to receive(:validate!).and_raise(error)
      expect(Raven).to receive(:capture_exception).with(error, 'Failed in KingslyCertbot::Runner.execute operation')
      KingslyCertbot::Runner.new(['--config', conf_file]).configure.execute
    end

    it 'should catch KingslyClient failure and log to raven' do
      error = StandardError.new('some error while fetching certificate')
      expect(KingslyCertbot::KingslyClient).to receive(:get_cert_bundle).and_raise(error)
      expect(Raven).to receive(:capture_exception).with(error, 'Failed in KingslyCertbot::Runner.execute operation')
      KingslyCertbot::Runner.new(['--config', conf_file]).configure.execute
    end

    it 'should initialize ipsec adapter and update_assets + restart service' do
      cert_bundle = double('')
      adapter = double('ipsec_adapter')
      allow(KingslyCertbot::KingslyClient).to receive(:get_cert_bundle).and_return(cert_bundle)
      expect(KingslyCertbot::IpSecCertAdapter).to receive(:new).with(cert_bundle, '/').and_return(adapter)
      expect(adapter).to receive(:update_assets).once
      expect(adapter).to receive(:restart_service).once
      KingslyCertbot::Runner.new(['--config', conf_file]).configure.execute
    end
  end
end
