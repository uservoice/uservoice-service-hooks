require 'spec_helper'

describe Services::Hipchat do
  describe '#perform' do
    let(:event) { "new_kudo" }
    let(:api_xml) { fixture(event) }

    before { stub_request(:post, 'https://api.hipchat.com:443/v1/rooms/message') }

    it 'should post to hipchat' do
      Services::Hipchat.new(event, {'auth_token' => 'auth_token', 'room' => 'room', 'notify' => true}, api_xml).perform
      a_request(:post, 'https://api.hipchat.com:443/v1/rooms/message').with(:body => {:auth_token => 'auth_token', :room_id => 'room', :from => 'UserVoice', :message =>  "Test Message Sender received <b>Kudos</b>! from Test Kudo Sender on <a href='http://test.uservoice.com/admin/tickets/1'>Test subject</a>", :notify => '1'}).should have_been_made
    end
  end

  describe '#message' do
    let(:event) { "new_#{model}" }
    let(:api_xml) { fixture(event) }
    subject { Services::Hipchat.new(event, nil, api_xml) }

    context 'new_kudo' do
      let(:model) { :kudo }
      it 'should generate a message' do
        subject.message.should == "Test Message Sender received <b>Kudos</b>! from Test Kudo Sender on <a href='http://test.uservoice.com/admin/tickets/1'>Test subject</a>"
      end
    end

    context 'new_ticket' do
      let(:model) { :ticket }
      it 'should generate a message' do
        subject.message.should == "<b>New ticket</b> from Test User: <a href='http://test.uservoice.com/admin/tickets/1'>Test subject</a>"
      end
    end

    context 'new_ticket_reply' do
      let(:model) { :ticket_message }
      let(:event) { 'new_ticket_reply' }
      it 'should generate a message' do
        subject.message.should == "<b>New ticket reply</b> from Test User on <a href='http://test.uservoice.com/admin/tickets/1'>Test subject</a>"
      end
    end

    context 'new_suggestion' do
      let(:model) { :suggestion }
      it 'should generate a message' do
        subject.message.should == "<b>New idea</b> by Test User: <a href='http://test.uservoice.com/forums/739109572-test-forum/suggestions/-test-suggestion'>Test suggestion</a>"
      end
    end

    context 'new_comment' do
      let(:model) { :comment }
      it 'should generate a message' do
        subject.message.should == "<b>New comment</b> by Test User on <a href='http://test.uservoice.com/forums/739109572-test-forum/suggestions/-test-suggestion'>Test suggestion</a>"
      end
    end

    context 'new_article' do
      let(:model) { :article }
      it 'should generate a message' do
        subject.message.should == "<b>New article</b> created by Test User: <a href='http://test.uservoice.com/knowledgebase/articles/-is-this-a-new-article-'>Is this a new article?</a>"
      end
    end

    context 'new_forum' do
      let(:model) { :forum }
      it 'should generate a message' do
        subject.message.should == "<b>New forum</b>: <a href='http://test.uservoice.com/forums/-test-forum'>Test forum</a> created by Test User"
      end
    end

    context 'suggestion_status_update' do
      let(:model) { :suggestion }
      let(:event) { 'suggestion_status_update' }
      it 'should generate a message' do
        subject.message.should == "<b>New idea status update</b> by Test User on <a href='http://test.uservoice.com/forums/739109572-test-forum/suggestions/-test-suggestion'>Test suggestion</a>"
      end
    end
  end
end

