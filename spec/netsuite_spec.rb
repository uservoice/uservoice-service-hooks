require 'spec_helper'

describe Services::Netsuite do
  describe '#perform' do
    let(:api_xml)       { fixture(:ticket) }
    let(:event)         { "new_ticket" }
  
    let(:data) {
      {
        'account_id'  => 'account',
        'email'       => 'test@example.com',
        'password'    => 'password',
        'role'        => @role,
        'company_id'  => '123'
      }
    }

    let(:body) {
      {
        'wsdl:record' => {
          'lists:title'            => 'Test subject',
          'lists:incomingMessage'  => "Name: Test User\nhttp://test.uservoice.com/admin/tickets/1\n\nTest message",
          'lists:email'            => 'test@example.com',
          'lists:customForm'       => "",
          'lists:company'          => "",
          :attributes!             => {
            'lists:customForm' => {'internalId' => -100},
            'lists:company'    => {'internalId' => 123}
          }
        },
        :attributes! => {
          "wsdl:record"=>{"xsi:type"=>"lists:SupportCase"}
        }
      }
    }

    before do
      Savon.config.hooks.define(:spec_test, :soap_request) do |_, request|
        @action = request.soap.input[1]
        raise "Unexpected action" unless @action == :add
        @actual_body = request.soap.body
        HTTPI::Response.new(200, {}, {})
      end
    end

    it 'should post to Netsuite' do
      @role = 1
      Services::Netsuite.new(event, data, api_xml).perform
      @action.should == :add
      @actual_body.inspect.should == body.inspect
    end

    it 'should post to Netsuite with no role' do
      Services::Netsuite.new(event, data, api_xml).perform
      @action.should == :add
      @actual_body.inspect.should == body.inspect
    end
  end
end
