module KingslyCertbot
  class CertBundle
    def initialize(private_key, full_chain)
      @private_key = private_key
      @full_chain  = full_chain
    end

    def save_to_file(file_path)
      #write
      puts @private_key
      puts @full_chain
    end
  end
end
