require 'fileutils'

RSpec.describe KingslyCertbot::CertBundle do
  context '==' do
    it 'should match two object as equals if tld, subdomain, private and full_chain matches' do
      first = KingslyCertbot::CertBundle.new('example.com', 'www', 'private', 'full_chain')
      second = KingslyCertbot::CertBundle.new('example.com', 'www', 'private', 'full_chain')
      expect(first).to eq(second)
      expect(first.hash).to eq(second.hash)
    end

    it 'should return false if other object type is nil' do
      first = KingslyCertbot::CertBundle.new('example.com', 'www', 'private', 'full_chain')
      expect(first).to_not eq(nil)
    end

    it 'should return false if other object type is nil' do
      first = KingslyCertbot::CertBundle.new('example.com', 'www', 'private', 'full_chain')
      expect(first).to_not eq(Object.new)
    end

    it 'should return false if attribute is different is different' do
      expect(KingslyCertbot::CertBundle.new('example.com', 'www', 'private', 'full_chain'))
          .to_not eq(KingslyCertbot::CertBundle.new('otherexample.com', 'www', 'private', 'full_chain'))
      expect(KingslyCertbot::CertBundle.new('example.com', 'www', 'private', 'full_chain'))
          .to_not eq(KingslyCertbot::CertBundle.new('example.com', 'www-diff', 'private', 'full_chain'))
      expect(KingslyCertbot::CertBundle.new('example.com', 'www', 'private', 'full_chain'))
          .to_not eq(KingslyCertbot::CertBundle.new('example.com', 'diff', 'other-private', 'full_chain'))
      expect(KingslyCertbot::CertBundle.new('example.com', 'www', 'private', 'full_chain'))
          .to_not eq(KingslyCertbot::CertBundle.new('example.com', 'diff', 'private', 'other-full_chain'))
    end
  end
end