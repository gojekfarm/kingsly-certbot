# frozen_string_literal: true

module KingslyCertbot
  class IpSecCertAdapter

    attr_reader :cert_backup_dir, :cert_private_dir, :certs_dir

    def initialize(cert_bundle, root = '/')
      raise 'passed parameter not of type CertBundle' if cert_bundle.class != KingslyCertbot::CertBundle
      @cert_bundle = cert_bundle
      root = root.end_with?('/') ? root : "#{root}/"
      @cert_backup_dir = "#{root}etc/ipsec.d/backup"
      @cert_private_dir = "#{root}etc/ipsec.d/private"
      @certs_dir = "#{root}etc/ipsec.d/certs"
    end

    def update_assets
      cert_filename = "#{@cert_bundle.subdomain}.#{@cert_bundle.tld}.pem"
      private_key_filepath = "#{cert_private_dir}/#{cert_filename}"
      cert_filepath = "#{certs_dir}/#{cert_filename}"

      if File.exist?(private_key_filepath) && File.exist?(cert_filepath)
        existing_private_key_content = File.read(private_key_filepath)
        existing_cert_content = File.read(cert_filepath)
        if existing_private_key_content == @cert_bundle.private_key && existing_cert_content == @cert_bundle.full_chain
          STDOUT.puts 'New certificate file is same as old cert file, skipping updating certificates'
          return
        else
          time = Time.now.strftime('%Y%m%d_%H%M%S')
          backup_dir = "#{cert_backup_dir}/#{time}"
          STDOUT.puts "Taking backup of existing certificates to #{backup_dir}"

          FileUtils.mkdir_p(backup_dir)
          FileUtils.mv(private_key_filepath, "#{backup_dir}/#{cert_filename}.private", force: true)
          FileUtils.mv(cert_filepath, "#{backup_dir}/#{cert_filename}.certs", force: true)
        end
      end

      FileUtils.mkdir_p(cert_private_dir) unless Dir.exist?(cert_private_dir)
      File.open(private_key_filepath, 'w') do |f|
        f.write(@cert_bundle.private_key)
      end

      FileUtils.mkdir_p(certs_dir) unless Dir.exist?(certs_dir)
      File.open(cert_filepath, 'w') do |f|
        f.write(@cert_bundle.full_chain)
      end
    end

    def restart_service
      result = %x(ipsec restart)
      STDERR.puts "ipsec restart command failed with exitstatus: '#{result.exitstatus}'" unless result.success?
      result.success?
    rescue StandardError => e
      STDERR.puts "ipsec restart command failed with error message: '#{e.message}'"
      false
    end
  end
end
