require 'webmock/rspec'
require 'services/base'
require 'services/campfire'
require 'services/flowdock'
require 'services/hipchat'
require 'services/netsuite'
require 'services/slack'
require 'json'

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :should }

  def fixture(name)
    File.read("spec/fixtures/xml/#{name}.xml")
  end
end
