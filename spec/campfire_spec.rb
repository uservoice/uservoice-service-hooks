require 'spec_helper'

describe Services::Campfire do
  describe '#perform' do
    let(:event) { "new_kudo" }
    let(:api_xml) { fixture(event) }
    let(:campfire_subdomain) { 'test' }
    let(:token) { 'test-token' }
    let(:room) { '123' }
    let(:data) { {'auth_token' => token, 'room' => room, 'subdomain' => campfire_subdomain} }
    let(:message) { "Peter Gibbons received Kudos! from Milton Waddams on I can't find my stapler -- https://initech.uservoice.com/admin/tickets/22" }
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
        subject.message.should == "Peter Gibbons received Kudos! from Milton Waddams on I can't find my stapler -- https://initech.uservoice.com/admin/tickets/22"
      end
    end

    context 'new_ticket' do
      let(:model) { :ticket }
      it 'should generate a message' do
        subject.message.should == "New ticket: I can't find my stapler from Milton Waddams -- https://initech.uservoice.com/admin/tickets/22"
      end
    end

    context 'new_ticket_reply' do
      let(:model) { :ticket_message }
      let(:event) { 'new_ticket_reply' }
      it 'should generate a message' do
        subject.message.should == "New ticket reply on I can't find my stapler from Milton Waddams -- https://initech.uservoice.com/admin/tickets/22"
      end
    end

    context 'new_suggestion' do
      let(:model) { :suggestion }
      it 'should generate a message' do
        subject.message.should == "New idea: Fax Machine on 2nd Floor is Broken from Michael.Bolton -- http://initech.uservoice.com/forums/1155-initech/suggestions/7839-fax-machine-on-2nd-floor-is-broken"
      end
    end

    context 'new_comment' do
      let(:model) { :comment }
      it 'should generate a message' do
        subject.message.should == "New comment on Reminder - New Coversheets on TPS Reports from @marcusnelson -- http://initech.uservoice.com/forums/1155-initech/suggestions/7843-reminder-new-coversheets-on-tps-reports"
      end
    end

    context 'new_article' do
      let(:model) { :article }
      it 'should generate a message' do
        subject.message.should == "New article: Proper TPS Cover Report Usage by Peter Gibbons -- http://initech.uservoice.com/knowledgebase/articles/98962-proper-tps-cover-report-usage"
      end
    end

    context 'new_forum' do
      let(:model) { :forum }
      it 'should generate a message' do
        subject.message.should == "New forum: Efficiency Improvements created by Peter Gibbons -- http://initech.uservoice.com/forums/171032-efficiency-improvements"
      end
    end

    context 'suggestion_status_update' do
      let(:model) { :suggestion }
      let(:event) { 'suggestion_status_update' }
      it 'should generate a message' do
        subject.message.should == "Idea status updated: Hawaiian Shirt Day set to planned by Peter Gibbons -- http://initech.uservoice.com/forums/1155-initech/suggestions/7842-hawaiian-shirt-day"
      end
    end
  end
end
