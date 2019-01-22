module KingslyCertbot
  class IpSecCertFileAdapter

    CERT_BACKUP_DIR = '/etc/ipsec.d/backup'
    CERT_PRIVATE_DIR = '/etc/ipsec.d/private'
    CERTS_DIR = '/etc/ipsec.d/certs'

    def initialize(cert_bundle)
      raise 'passed parameter not of type CertBundle' if cert_bundle.class != KingslyCertbot::CertBundle
      @cert_bundle = cert_bundle
    end

    def write_cert_files
      time = Time.now.strftime('%Y%m%d_%H%M%S')
      backup_dir = "#{CERT_BACKUP_DIR}/#{time}"
      cert_filename = "#{@cert_bundle.subdomain}.#{@cert_bundle.tld}.pem"

      FileUtils.mkdir_p(backup_dir)
      FileUtils.mv("#{CERT_PRIVATE_DIR}/#{cert_filename}", "#{backup_dir}/#{cert_filename}.private", force: true)
      FileUtils.mv("#{CERTS_DIR}/#{cert_filename}", "#{backup_dir}/#{cert_filename}.certs", force: true)

      File.open("#{CERT_PRIVATE_DIR}/#{cert_filename}", 'w') do |f|
        f.write(@cert_bundle.private_key)
      end

      File.open("#{CERTS_DIR}/#{cert_filename}", 'w') do |f|
        f.write(@cert_bundle.private_key)
      end
    end
  end
end