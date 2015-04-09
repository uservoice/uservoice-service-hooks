require 'spec_helper'

describe Services::Nutshell do
  describe '#perform' do
    before { stub_request(:post, 'https://app.nutshell.com/api/v1/public/uservoice/1:a56de74ab335d5a5e7f863b65705493a051082d9') }

    context 'new_ticket' do
      let(:event) { "new_ticket" }
      let(:api_xml) { fixture(event) }
      it 'should post to new ticket' do
            nutshell = Services::Nutshell.new(event, {'api_key' => '1:a56de74ab335d5a5e7f863b65705493a051082d9'}, api_xml)
            nutshell.perform
            a_request(:post, 'https://app.nutshell.com/api/v1/public/uservoice/1:a56de74ab335d5a5e7f863b65705493a051082d9').with(:body => nutshell.api_hash).should have_been_made
      end
    end

    context 'new_ticket_reply' do
      let(:event) { "new_ticket_reply" }
      let(:api_xml) { fixture(event) }
      it 'should post to new ticket' do
            nutshell = Services::Nutshell.new(event, {'api_key' => '1:a56de74ab335d5a5e7f863b65705493a051082d9'}, api_xml)
            nutshell.perform
            a_request(:post, 'https://app.nutshell.com/api/v1/public/uservoice/1:a56de74ab335d5a5e7f863b65705493a051082d9').with(:body => nutshell.api_hash).should have_been_made
      end
    end

    context 'new_ticket_admin_reply' do
      let(:event) { "new_ticket_admin_reply" }
      let(:api_xml) { fixture(event) }
      it 'should post to new ticket' do
            nutshell = Services::Nutshell.new(event, {'api_key' => '1:a56de74ab335d5a5e7f863b65705493a051082d9'}, api_xml)
            nutshell.perform
            a_request(:post, 'https://app.nutshell.com/api/v1/public/uservoice/1:a56de74ab335d5a5e7f863b65705493a051082d9').with(:body => nutshell.api_hash).should have_been_made
      end
    end
  end
end
