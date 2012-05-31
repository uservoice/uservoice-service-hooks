#!/usr/bin/ruby

# This Ruby script can be used to test the createCase.js RESTlet deployed to Netsuite. This is
# important for making sure all permissions are set properly for the web services user.
#
# Put the account, email, password, and role for the web services user in the NETSUITE_AUTH
# environment variable as a comma-separated list. Put the URL of the RESTlet in the 
# NETSUITE_RESTLET_URL environment variable.

require 'net/http'
require 'net/https'

require File.join('.', File.dirname(__FILE__), '../../lib/services/base.rb')
require File.join('.', File.dirname(__FILE__), '../../lib/services/netsuite.rb')

ACCOUNT, EMAIL, PASSWORD, ROLE = ENV['NETSUITE_AUTH'].split(',')
URL = ENV['NETSUITE_RESTLET_URL']
DEBUG_COOKIE = nil

DATA = {
  'account'       => ACCOUNT,
  'email'         => EMAIL,
  'password'      => PASSWORD,
  'external_url'  => URL,
  'role'          => ROLE
}

PAYLOAD = { 
  "title"           => 'Test subject',
  "incomingmessage" => "http://test.uservoice.com/admin/tickets/1\n\nTest message",
  "firstname"       => 'Test',
  "lastname"        => 'User',
  "email"           => 'test@example.com',
  "customfields"    => { 'product' => 'Test Product', 'company' => 'Test Company' }
}

print "Sending payload..."
sent = Services::Netsuite.send_request(DATA, PAYLOAD, DEBUG_COOKIE)
puts sent ? "success" : "failure"






