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
    let(:tld) {'example.com'}
    let(:subdomain) {'www'}
    let(:cert_bundle) {KingslyCertbot::CertBundle.new(
        tld,
        subdomain,
        "-----BEGIN RSA PRIVATE KEY-----\nFOO...\n-----END RSA PRIVATE KEY-----\n",
        "-----BEGIN CERTIFICATE-----\nBAR...\n-----END CERTIFICATE-----\n"
    )}


    it 'should just create new cert files if old files do not exists' do
      expect(File).to receive(:exist?).with("/etc/ipsec.d/private/#{subdomain}.#{tld}.pem").and_return(true)
      expect(File).to receive(:exist?).with("/etc/ipsec.d/certs/#{subdomain}.#{tld}.pem").and_return(false)

      expect(FileUtils).to_not receive(:mkdir_p)
      expect(FileUtils).to_not receive(:mv)

      expect_to_write_to_file("/etc/ipsec.d/private/#{subdomain}.#{tld}.pem", cert_bundle.private_key)
      expect_to_write_to_file("/etc/ipsec.d/certs/#{subdomain}.#{tld}.pem", cert_bundle.full_chain)

      adapter = KingslyCertbot::IpSecCertAdapter.new(cert_bundle)
      adapter.update_assets
    end

    context 'old cert files exists' do
      before(:each) do
        allow(Time).to receive_message_chain(:now, :strftime).and_return('20190121_172725')
        expect(File).to receive(:exist?).with("/etc/ipsec.d/private/#{subdomain}.#{tld}.pem").and_return(true)
        expect(File).to receive(:exist?).with("/etc/ipsec.d/certs/#{subdomain}.#{tld}.pem").and_return(true)
      end

      it 'should replace old files to backup folder named as current timestamp' do
        expect(File).to receive(:read).with("/etc/ipsec.d/private/#{subdomain}.#{tld}.pem").and_return("-----BEGIN RSA PRIVATE KEY-----\nDIFFERENT FOO...\n-----END RSA PRIVATE KEY-----\n")
        expect(File).to receive(:read).with("/etc/ipsec.d/certs/#{subdomain}.#{tld}.pem").and_return("-----BEGIN CERTIFICATE-----\nBAR...\n-----END CERTIFICATE-----\n")

        expect(FileUtils).to receive(:mkdir_p).with('/etc/ipsec.d/backup/20190121_172725')
        expect(FileUtils).to receive(:mv).with("/etc/ipsec.d/private/#{subdomain}.#{tld}.pem", "/etc/ipsec.d/backup/20190121_172725/#{subdomain}.#{tld}.pem.private", force: true)
        expect(FileUtils).to receive(:mv).with("/etc/ipsec.d/certs/#{subdomain}.#{tld}.pem", "/etc/ipsec.d/backup/20190121_172725/#{subdomain}.#{tld}.pem.certs", force: true)

        expect(STDOUT).to receive(:puts).with('Taking backup of existing certificates to /etc/ipsec.d/backup/20190121_172725')

        expect_to_write_to_file("/etc/ipsec.d/private/#{subdomain}.#{tld}.pem", cert_bundle.private_key)
        expect_to_write_to_file("/etc/ipsec.d/certs/#{subdomain}.#{tld}.pem", cert_bundle.full_chain)

        adapter = KingslyCertbot::IpSecCertAdapter.new(cert_bundle)
        adapter.update_assets
      end

      it 'should not replace the existing cert file if the content is same for both fullchain and private key' do
        expect(File).to receive(:read).with("/etc/ipsec.d/private/#{subdomain}.#{tld}.pem").and_return("-----BEGIN RSA PRIVATE KEY-----\nFOO...\n-----END RSA PRIVATE KEY-----\n")
        expect(File).to receive(:read).with("/etc/ipsec.d/certs/#{subdomain}.#{tld}.pem").and_return("-----BEGIN CERTIFICATE-----\nBAR...\n-----END CERTIFICATE-----\n")
        expect(STDOUT).to receive(:puts).with('New certificate file is same as old cert file, skipping updating certificates')
        adapter = KingslyCertbot::IpSecCertAdapter.new(cert_bundle)
        adapter.update_assets
      end

      it 'should replace the existing cert file if the content is not same for fullchain but same for private key' do
        expect(File).to receive(:read).with("/etc/ipsec.d/private/#{subdomain}.#{tld}.pem").and_return("-----BEGIN RSA PRIVATE KEY-----\nFOO...\n-----END RSA PRIVATE KEY-----\n")
        expect(File).to receive(:read).with("/etc/ipsec.d/certs/#{subdomain}.#{tld}.pem").and_return("-----BEGIN CERTIFICATE-----\nDifferent cert...\n-----END CERTIFICATE-----\n")
        expect(STDOUT).to receive(:puts).with('Taking backup of existing certificates to /etc/ipsec.d/backup/20190121_172725')
        expect_to_write_to_file("/etc/ipsec.d/private/#{subdomain}.#{tld}.pem", cert_bundle.private_key)
        expect_to_write_to_file("/etc/ipsec.d/certs/#{subdomain}.#{tld}.pem", cert_bundle.full_chain)
        adapter = KingslyCertbot::IpSecCertAdapter.new(cert_bundle)
        adapter.update_assets
      end

      it 'should replace the existing private key if the content is not same for private key but same for fullchain' do
        expect(File).to receive(:read).with("/etc/ipsec.d/private/#{subdomain}.#{tld}.pem").and_return("-----BEGIN RSA PRIVATE KEY-----\nFOO...\n-----END RSA DIFFERENT PRIVATE KEY-----\n")
        expect(File).to receive(:read).with("/etc/ipsec.d/certs/#{subdomain}.#{tld}.pem").and_return("-----BEGIN CERTIFICATE-----\nBAR...\n-----END CERTIFICATE-----\n")
        expect(STDOUT).to receive(:puts).with('Taking backup of existing certificates to /etc/ipsec.d/backup/20190121_172725')
        expect_to_write_to_file("/etc/ipsec.d/private/#{subdomain}.#{tld}.pem", cert_bundle.private_key)
        expect_to_write_to_file("/etc/ipsec.d/certs/#{subdomain}.#{tld}.pem", cert_bundle.full_chain)
        adapter = KingslyCertbot::IpSecCertAdapter.new(cert_bundle)
        adapter.update_assets
      end
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

  def expect_to_write_to_file(filepath, file_content)
    file_double = File.instance_double('File')
    expect(File).to receive(:open).with(filepath, 'w').and_yield(file_double)
    expect(file_double).to receive(:write).with(file_content)
  end
end
