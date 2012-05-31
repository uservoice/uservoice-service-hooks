require 'spec_helper'

describe Services::Netsuite do
  describe '#perform' do
    let(:api_xml)       { fixture(:ticket) }
    let(:event)         { "new_ticket" }
    let(:account)       { 'account' }
    let(:email)         { 'test@example.com' }
    let(:password)      { 'password' }
    let(:external_url)  { 'https://example.com/case' }
    let(:authorization) { "NLAuth nlauth_account=#{account}, nlauth_email=#{email}, nlauth_signature=#{password}" + (@role ? ", nlauth_role=#{@role}":"") }

    let(:data) {
      {'account' => account, 'email' => email, 'password' => password, 'role' => @role, 'external_url' => external_url}
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

    let(:headers) {{
      "Authorization" => authorization,
      "Content-Type"  => "application/json"
    }}

    before { stub_request(:post, external_url) }

    it 'should post to Netsuite' do
      @role = 1
      Services::Netsuite.new(event, data, api_xml).perform
      a_request(:post, external_url).with(:body => body, :headers => headers).should have_been_made
    end

    it 'should post to Netsuite with no role' do
      Services::Netsuite.new(event, data, api_xml).perform
      a_request(:post, external_url).with(:body => body, :headers => headers).should have_been_made
    end
  end
end
