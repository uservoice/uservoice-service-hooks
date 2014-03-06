require 'spec_helper'

describe Services::Hipchat do
  describe '#perform' do
    let(:event) { "new_kudo" }
    let(:api_xml) { fixture(event) }

    before { stub_request(:post, 'https://api.hipchat.com:443/v1/rooms/message') }

    it 'should post to hipchat' do
      Services::Hipchat.new(event, {'auth_token' => 'auth_token', 'room' => 'room', 'notify' => true}, api_xml).perform
      a_request(:post, 'https://api.hipchat.com:443/v1/rooms/message').with(:body => {:auth_token => 'auth_token', :room_id => 'room', :from => 'UserVoice', :message =>  "Peter Gibbons received <b>Kudos</b>! from Milton Waddams on <a href='https://initech.uservoice.com/admin/tickets/22'>I can't find my stapler</a>", :notify => '1'}).should have_been_made
    end
  end

  describe '#message' do
    let(:event) { "new_#{model}" }
    let(:api_xml) { fixture(event) }
    subject { Services::Hipchat.new(event, nil, api_xml) }

    context 'new_kudo' do
      let(:model) { :kudo }
      it 'should generate a message' do
        subject.message.should == "Peter Gibbons received <b>Kudos</b>! from Milton Waddams on <a href='https://initech.uservoice.com/admin/tickets/22'>I can't find my stapler</a>"
      end
    end

    context 'new_ticket' do
      let(:model) { :ticket }
      it 'should generate a message' do
        subject.message.should == "<b>New ticket</b> from Milton Waddams: <a href='https://initech.uservoice.com/admin/tickets/22'>I can't find my stapler</a>"
      end
    end

    context 'new_ticket_reply' do
      let(:model) { :ticket_message }
      let(:event) { 'new_ticket_reply' }
      it 'should generate a message' do
        subject.message.should == "<b>New ticket reply</b> from Milton Waddams on <a href='https://initech.uservoice.com/admin/tickets/22'>I can't find my stapler</a>"
      end
    end

    context 'new_suggestion' do
      let(:model) { :suggestion }
      it 'should generate a message' do
        subject.message.should == "<b>New idea</b> by Michael.Bolton: <a href='http://initech.uservoice.com/forums/1155-initech/suggestions/7839-fax-machine-on-2nd-floor-is-broken'>Fax Machine on 2nd Floor is Broken</a>"
      end
    end

    context 'new_comment' do
      let(:model) { :comment }
      it 'should generate a message' do
        subject.message.should == "<b>New comment</b> by @marcusnelson on <a href='http://initech.uservoice.com/forums/1155-initech/suggestions/7843-reminder-new-coversheets-on-tps-reports'>Reminder - New Coversheets on TPS Reports</a>"
      end
    end

    context 'new_article' do
      let(:model) { :article }
      it 'should generate a message' do
        subject.message.should == "<b>New article</b> created by Peter Gibbons: <a href='http://initech.uservoice.com/knowledgebase/articles/98962-proper-tps-cover-report-usage'>Proper TPS Cover Report Usage</a>"
      end
    end

    context 'new_forum' do
      let(:model) { :forum }
      it 'should generate a message' do
        subject.message.should == "<b>New forum</b>: <a href='http://initech.uservoice.com/forums/171032-efficiency-improvements'>Efficiency Improvements</a> created by Peter Gibbons"
      end
    end

    context 'suggestion_status_update' do
      let(:model) { :suggestion }
      let(:event) { 'suggestion_status_update' }
      it 'should generate a message' do
        subject.message.should == "<b>New idea status update</b> by Peter Gibbons on <a href='http://initech.uservoice.com/forums/1155-initech/suggestions/7842-hawaiian-shirt-day'>Hawaiian Shirt Day</a>"
      end
    end
  end
end

