#!/usr/bin/ruby

# This Ruby script can be used to test the SOAP call.
#
# Put the account ID, email, password, and role for the web services user in the NS_ACCOUNT_ID, NS_EMAIL,
# NS_PASSWORD, and optional NS_ROLE environment variables. Set NS_COMPANY_ID to the Company ID used for all Cases.
# You can optionally set the endpoint URL in NS_ENDPOINT_URL.

require 'net/http'
require 'net/https'

require File.join('.', File.dirname(__FILE__), '../../lib/services/base.rb')
require File.join('.', File.dirname(__FILE__), '../../lib/services/netsuite.rb')

ENV['NS_ENDPOINT_URL'] ||= 'https://webservices.sandbox.netsuite.com/services/NetSuitePort_2011_2'

unless ENV['NS_ACCOUNT_ID'] && ENV['NS_EMAIL'] && ENV['NS_PASSWORD'] && ENV['NS_COMPANY_ID']
  puts "Ensure that all your environment variables are set: NS_ACCOUNT_ID, NS_EMAIL, NS_PASSWORD, NS_COMPANY_ID"
  exit(-1)
end

DATA = {
  'account_id'    => ENV['NS_ACCOUNT_ID'],
  'email'         => ENV['NS_EMAIL'],
  'password'      => ENV['NS_PASSWORD'],
  'role'          => ENV['NS_ROLE'],
  'company_id'    => ENV['NS_COMPANY_ID']
}

FIELDS = { 
  "title"           => 'Test subject',
  "incomingMessage" => "http://test.uservoice.com/admin/tickets/1\n\nTest message",
  "firstName"       => 'Test',
  "lastName"        => 'User',
  "email"           => 'test@example.com'
}

print "Sending SOAP request..."
response = Services::Netsuite.send_request(DATA, FIELDS, :endpoint => ENV['NS_ENDPOINT_URL'], :debug => true)
puts response.success? ? "Success" : "#{response.error_code}: #{response.error_message}"






