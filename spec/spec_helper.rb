require 'bundler/setup'
require 'kingsly_certbot'
require 'webmock/rspec'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    $logger = double('logger')
    allow($logger).to receive(:debug)
    allow($logger).to receive(:info)
    allow($logger).to receive(:warn)
    allow($logger).to receive(:error)
    allow($logger).to receive(:fatal)
  end
end
