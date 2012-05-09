require 'spec_helper'

describe Services::Netsuite do
  describe '#perform' do
    let(:api_xml)       { fixture(:ticket) }
    let(:event)         { "new_ticket" }
    let(:account)       { 'account' }
    let(:email)         { 'test@example.com' }
    let(:password)      { 'password' }
    let(:role)          { '15' }
    let(:external_url)  { 'http://example.com/case' }
    let(:authorization) { "NLAuth nlauth_account=#{account}, nlauth_email=#{email}, nlauth_signature=#{password}, nlauth_role=#{role}" }

    let(:data) {
      {'account' => account, 'email' => email, 'password' => password, 'role' => role, 'external_url' => external_url}
    }

    let(:body) {
        { "subject"     => 'Test subject',
          "description" => 'Test message',
          "name"        => 'Test User',
          "email"       => 'test@example.com',
          "ticket_url"  => 'http://test.uservoice.com/admin/tickets/1'
        }.to_json
    }

    let(:headers) { { "Authorization" => authorization, "Content-Type" => "application/json" } }

    before { stub_request(:post, external_url) }

    it 'should post to Netsuite' do
      Services::Netsuite.new(event, data, api_xml).perform
      a_request(:post, external_url).with(:body => body, headers => headers).should have_been_made
    end
  end
end
