# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe KingslyCertbot::IpSecCertAdapter do
  context 'integration test' do
    let(:tld) { 'example.com' }
    let(:subdomain) { 'www' }
    let(:cert_bundle) do
      KingslyCertbot::CertBundle.new(tld,
                                     subdomain,
                                     "-----BEGIN RSA PRIVATE KEY-----\nFOO...\n-----END RSA PRIVATE KEY-----\n",
                                     "-----BEGIN CERTIFICATE-----\nBAR...\n-----END CERTIFICATE-----\n")
    end

    it 'should write the certs to file if no certs exist in the directory' do
      tmpdir = Dir.mktmpdir
      FileUtils.rm_rf("#{tmpdir}/*")
      ipsec_adapter = KingslyCertbot::IpSecCertAdapter.new(cert_bundle, tmpdir)
      ipsec_adapter.update_assets
      private_cert_exists = File.exist?("#{tmpdir}/etc/ipsec.d/private/#{subdomain}.#{tld}.pem")
      cert_key_exists = File.exist?("#{tmpdir}/etc/ipsec.d/certs/#{subdomain}.#{tld}.pem")
      expect(private_cert_exists).to eq(true)
      expect(cert_key_exists).to eq(true)
    end

    it 'should create newer certs if certs exist already and move the older ones to a backup directory' do
      tmpdir = Dir.mktmpdir
      FileUtils.rm_rf("#{tmpdir}/*")
      FileUtils.mkdir_p("#{tmpdir}/etc/ipsec.d/private")
      FileUtils.mkdir_p("#{tmpdir}/etc/ipsec.d/certs")
      old_private_key = "-----BEGIN RSA PRIVATE KEY-----\nOLD...\n-----END RSA PRIVATE KEY-----\n"
      old_cert_key = "-----BEGIN CERTIFICATE-----\nBAR...\n-----END CERTIFICATE-----\n"
      File.write("#{tmpdir}/etc/ipsec.d/private/www.example.com.pem", old_private_key)
      File.write("#{tmpdir}/etc/ipsec.d/certs/www.example.com.pem", old_cert_key)

      ipsec_adapter = KingslyCertbot::IpSecCertAdapter.new(cert_bundle, tmpdir)
      ipsec_adapter.update_assets

      backup_dir_timestamp = Dir["#{tmpdir}/etc/ipsec.d/backup/*"]
      expect(backup_dir_timestamp.size).to eq(1)
      backup_private_filepath = "#{backup_dir_timestamp[0]}/#{subdomain}.#{tld}.pem.private"
      backup_cert_filepath = "#{backup_dir_timestamp[0]}/#{subdomain}.#{tld}.pem.certs"
      old_private_file_exists = File.exist?(backup_private_filepath)
      old_cert_file_exists = File.exist?(backup_cert_filepath)

      expect(old_private_file_exists).to eq(true)
      expect(old_cert_file_exists).to eq(true)
      expect(File.read(backup_cert_filepath)).to eq(old_cert_key)
      expect(File.read(backup_private_filepath)).to eq(old_private_key)
    end
  end
end
