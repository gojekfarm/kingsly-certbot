require 'spec_helper'
include RSpec::Mocks::ExampleMethods

RSpec.describe KingslyCertbot::IpSecCertFileAdapter do
  context 'guard clause' do
    it 'raises exception if passed parameter not of type CertBundle' do
      expect {KingslyCertbot::IpSecCertFileAdapter.new(nil)}.to raise_exception('passed parameter not of type CertBundle')
      expect {KingslyCertbot::IpSecCertFileAdapter.new(Object.new)}.to raise_exception('passed parameter not of type CertBundle')
    end

    it 'should not raise exception if valid parameter is passed' do
      KingslyCertbot::IpSecCertFileAdapter.new(KingslyCertbot::CertBundle.new(nil, nil, nil, nil))
    end
  end

  context 'write_cert_files' do
    it 'should replace old files to backup folder named as current timestamp' do
      tld = 'example.com'
      subdomain = 'www'
      cert_bundle = KingslyCertbot::CertBundle.new(tld, subdomain, 'private_key', 'full_chain')
      allow(Time).to receive_message_chain(:now, :strftime).and_return('20190121_172725')
      expect(FileUtils).to receive(:mkdir_p).with('/etc/ipsec.d/backup/20190121_172725')
      expect(FileUtils).to receive(:mv).with("/etc/ipsec.d/private/#{subdomain}.#{tld}.pem", "/etc/ipsec.d/backup/20190121_172725/#{subdomain}.#{tld}.pem.private", force: true)
      expect(FileUtils).to receive(:mv).with("/etc/ipsec.d/certs/#{subdomain}.#{tld}.pem", "/etc/ipsec.d/backup/20190121_172725/#{subdomain}.#{tld}.pem.certs", force: true)

      private_file_double = File.instance_double('File')
      expect(File).to receive(:open).with("/etc/ipsec.d/private/#{subdomain}.#{tld}.pem", 'w').and_yield(private_file_double)
      expect(private_file_double).to receive(:write).with(cert_bundle.private_key)

      cert_file_double = File.instance_double('File')
      expect(File).to receive(:open).with("/etc/ipsec.d/certs/#{subdomain}.#{tld}.pem", 'w').and_yield(cert_file_double)
      expect(cert_file_double).to receive(:write).with(cert_bundle.private_key)

      adapter = KingslyCertbot::IpSecCertFileAdapter.new(cert_bundle)
      adapter.write_cert_files
    end
  end
end
