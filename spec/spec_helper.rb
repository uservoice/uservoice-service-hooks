require 'webmock/rspec'
require 'services/base'
require 'services/campfire'
require 'services/flowdock'
require 'services/hipchat'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  def fixture(name)
    File.read("spec/fixtures/#{name}.xml")
  end
end
