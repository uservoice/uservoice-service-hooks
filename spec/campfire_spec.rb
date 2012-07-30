require 'spec_helper'

describe Services::Campfire do
  describe '#perform' do
    let(:event) { "new_kudo" }
    let(:api_xml) { fixture(event) }
    let(:campfire_subdomain) { 'test' }
    let(:token) { 'test-token' }
    let(:room) { '123' }
    let(:data) { {'auth_token' => token, 'room' => room, 'subdomain' => campfire_subdomain} }
    let(:message) { 'Test Message Sender received Kudos! from Test Kudo Sender on Test subject -- http://test.uservoice.com/admin/tickets/1' }
    let(:body) { "<message><type>TextMessage</type><body>#{message}</body></message>" }
    let(:stub_url) { "https://#{token}:X@#{campfire_subdomain}.campfirenow.com:443/room/#{room}/speak.xml" }

    before { stub_request(:post, stub_url) }

    it 'should post to campfire' do
      Services::Campfire.new(event, data, api_xml).perform
      a_request(:post, stub_url).with(:body => body).should have_been_made
    end
  end

  describe '#message' do
    let(:event) { "new_#{model}" }
    let(:api_xml) { fixture(event) }
    subject { Services::Campfire.new(event, nil, api_xml) }

    context 'new_kudo' do
      let(:model) { :kudo }
      it 'should generate a message' do
        subject.message.should == "Test Message Sender received Kudos! from Test Kudo Sender on Test subject -- http://test.uservoice.com/admin/tickets/1"
      end
    end

    context 'new_ticket' do
      let(:model) { :ticket }
      it 'should generate a message' do
        subject.message.should == "New ticket: Test subject from Test User -- http://test.uservoice.com/admin/tickets/1"
      end
    end

    context 'new_ticket_reply' do
      let(:model) { :ticket_message }
      let(:event) { 'new_ticket_reply' }
      it 'should generate a message' do
        subject.message.should == "New ticket reply on Test subject from Test User -- http://test.uservoice.com/admin/tickets/1"
      end
    end

    context 'new_suggestion' do
      let(:model) { :suggestion }
      it 'should generate a message' do
        subject.message.should == "New idea: Test suggestion from Test User -- http://test.uservoice.com/forums/739109572-test-forum/suggestions/-test-suggestion"
      end
    end

    context 'new_comment' do
      let(:model) { :comment }
      it 'should generate a message' do
        subject.message.should == "New comment on Test suggestion from Test User -- http://test.uservoice.com/forums/739109572-test-forum/suggestions/-test-suggestion"
      end
    end

    context 'new_article' do
      let(:model) { :article }
      it 'should generate a message' do
        subject.message.should == "New article: Is this a new article? by Test User -- http://test.uservoice.com/knowledgebase/articles/-is-this-a-new-article-"
      end
    end

    context 'new_forum' do
      let(:model) { :forum }
      it 'should generate a message' do
        subject.message.should == "New forum: Test forum created by Test User -- http://test.uservoice.com/forums/-test-forum"
      end
    end

    context 'suggestion_status_update' do
      let(:model) { :suggestion }
      let(:event) { 'suggestion_status_update' }
      it 'should generate a message' do
        subject.message.should == "Idea status updated: Test suggestion set to planned by Test User -- http://test.uservoice.com/forums/739109572-test-forum/suggestions/-test-suggestion"
      end
    end
  end
end
