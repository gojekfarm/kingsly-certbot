module KingslyCertbot
  class CertBundle
    attr_reader :private_key, :full_chain
    def initialize(private_key, full_chain)
      @private_key = private_key
      @full_chain  = full_chain
    end

    def ==(other_cert_bundle)
      (@private_key == other_cert_bundle.private_key) && (@full_chain == other_cert_bundle.full_chain)
    end

    def hash
      @private_key.hash + @full_chain.hash
    end

    def save_to_file(file_path)
      # TODO: write to file
      puts @private_key
      puts @full_chain
    end
  end
end
