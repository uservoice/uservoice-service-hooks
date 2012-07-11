require 'spec_helper'

describe Services::Netsuite do
  describe '#perform' do
    let(:api_xml)       { fixture(:ticket) }
    let(:event)         { "new_ticket" }
    let(:account)       { 'account' }
    let(:email)         { 'test@example.com' }
    let(:password)      { 'password' }
    let(:external_url)  { 'https://example.com/case' }
  
    let(:data) {
      {'account_id' => account, 'email' => email, 'password' => password, 'role' => @role}
    }

    let(:body) {
        { "title"           => 'Test subject',
          "incomingmessage" => "http://test.uservoice.com/admin/tickets/1\n\nTest message",
          "firstname"       => 'Test',
          "lastname"        => 'User',
          "email"           => 'test@example.com',
          "customfields"    => nil
        }.to_json
    }

    let(:body) {
      {
        'wsdl:record' => {
          'lists:title'            => 'Test subject',
          'lists:incomingMessage'  => "Name: Test User\nhttp://test.uservoice.com/admin/tickets/1\n\nTest message",
          'lists:email'            => 'test@example.com',
          'lists:origin'           => {'core:name' => 'Web', 'core:internalId' => '-5'},
          :attributes!             => {
            "lists:origin" => {"xsi:type" => "core:RecordRef"}
          }
        },
        :attributes! => {
          "wsdl:record"=>{"xsi:type"=>"lists:SupportCase"}
        }
      }
    }

    before do
      Savon.config.hooks.define(:spec_test, :soap_request) do |_, request|
        action = request.soap.input[1]

        case action
        when :getSelectValue
          HTTPI::Response.new(200, {}, File.read('spec/fixtures/netsuite/origins.xml'))
        when :add
          actual_body = request.soap.body
          raise "expected #{body.inspect} to be sent, got: #{actual_body.inspect}" unless actual_body == body
          HTTPI::Response.new(200, {}, {})
        else
          raise "Unexpected action: #{action.inspect}"
        end
      end
    end

    it 'should post to Netsuite' do
      @role = 1
      Services::Netsuite.new(event, data, api_xml).perform
    end

    it 'should post to Netsuite with no role' do
      Services::Netsuite.new(event, data, api_xml).perform
    end
  end
end
