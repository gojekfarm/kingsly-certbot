require "spec_helper"

RSpec.describe KingslyCertbot do
  let(:kingsly_host) { 'kingsly.something.com' }
  it "allows configuration for fetching kingsly certbot" do
    KingslyCertbot.configure do |config|
      config.kingsly_host = kingsly_host
    end

    expect(KingslyCertbot.configuration.kingsly_host).to eq kingsly_host
  end

  after :each do
    KingslyCertbot.configuration = nil
  end
end
