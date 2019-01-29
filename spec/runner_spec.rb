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
      expect(KingslyCertbot.configuration.sentry_dsn).to eq(sentry_dsn)
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
end
