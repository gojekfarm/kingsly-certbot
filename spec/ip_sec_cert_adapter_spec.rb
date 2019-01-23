require 'spec_helper'
include RSpec::Mocks::ExampleMethods

RSpec.describe KingslyCertbot::IpSecCertAdapter do
  context 'guard clause' do
    it 'raises exception if passed parameter not of type CertBundle' do
      expect {KingslyCertbot::IpSecCertAdapter.new(nil)}.to raise_exception('passed parameter not of type CertBundle')
      expect {KingslyCertbot::IpSecCertAdapter.new(Object.new)}.to raise_exception('passed parameter not of type CertBundle')
    end

    it 'should not raise exception if valid parameter is passed' do
      KingslyCertbot::IpSecCertAdapter.new(KingslyCertbot::CertBundle.new(nil, nil, nil, nil))
    end
  end

  context 'write_cert_files' do
    it 'should replace old files to backup folder named as current timestamp' do
      tld = 'example.com'
      subdomain = 'www'
      cert_bundle = KingslyCertbot::CertBundle.new(
          tld,
          subdomain,
          "-----BEGIN RSA PRIVATE KEY-----\nFOO...\n-----END RSA PRIVATE KEY-----\n",
          "-----BEGIN CERTIFICATE-----\nBAR...\n-----END CERTIFICATE-----\n"
      )
      allow(Time).to receive_message_chain(:now, :strftime).and_return('20190121_172725')
      expect(FileUtils).to receive(:mkdir_p).with('/etc/ipsec.d/backup/20190121_172725')
      expect(FileUtils).to receive(:mv).with("/etc/ipsec.d/private/#{subdomain}.#{tld}.pem", "/etc/ipsec.d/backup/20190121_172725/#{subdomain}.#{tld}.pem.private", force: true)
      expect(FileUtils).to receive(:mv).with("/etc/ipsec.d/certs/#{subdomain}.#{tld}.pem", "/etc/ipsec.d/backup/20190121_172725/#{subdomain}.#{tld}.pem.certs", force: true)

      private_file_double = File.instance_double('File')
      expect(File).to receive(:open).with("/etc/ipsec.d/private/#{subdomain}.#{tld}.pem", 'w').and_yield(private_file_double)
      expect(private_file_double).to receive(:write).with(cert_bundle.private_key)

      cert_file_double = File.instance_double('File')
      expect(File).to receive(:open).with("/etc/ipsec.d/certs/#{subdomain}.#{tld}.pem", 'w').and_yield(cert_file_double)
      expect(cert_file_double).to receive(:write).with(cert_bundle.full_chain)

      adapter = KingslyCertbot::IpSecCertAdapter.new(cert_bundle)
      adapter.update_assets
    end
  end

  context 'restart_service' do
    it 'should call ipsec restart and return true if success' do
      adapter = KingslyCertbot::IpSecCertAdapter.new(KingslyCertbot::CertBundle.new(nil, nil, nil, nil))
      expect(adapter).to receive(:`).with('ipsec restart').and_return(double('process status', success?: true))
      expect(adapter.restart_service).to eq(true)
    end

    it 'should return false and print error to standard error if restart_service returns false' do
      adapter = KingslyCertbot::IpSecCertAdapter.new(KingslyCertbot::CertBundle.new(nil, nil, nil, nil))
      expect(adapter).to receive(:`).with('ipsec restart').and_return(double('process status', success?: false, exitstatus: 127))
      expect(STDERR).to receive(:puts).with("ipsec restart command failed with exitstatus: '127'")
      expect(adapter.restart_service).to eq(false)
    end

    it 'should return false and print error to standard error if command throws exception' do
      adapter = KingslyCertbot::IpSecCertAdapter.new(KingslyCertbot::CertBundle.new(nil, nil, nil, nil))
      expect(adapter).to receive(:`).with('ipsec restart').and_raise(StandardError.new('failed to find command ipsec'))
      expect(STDERR).to receive(:puts).with("ipsec restart command failed with error message: 'failed to find command ipsec'")
      expect(adapter.restart_service).to eq(false)
    end
  end
end
