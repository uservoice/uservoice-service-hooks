require 'spec_helper'

describe Services::Slack do
  describe '#perform' do
    let(:event) { "new_kudo" }
    let(:api_xml) { fixture(event) }

    before { stub_request(:post, 'https://hooks.slack.com/services/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') }

    it 'should post to Slack' do
      Services::Slack.new(event, {'url_hash' => 'T02K38RR6/B03BDUGTX/aXU9IYaWtwsTWazDcW5uUeLY'}, api_xml).perform
      a_request(:post, 'https://hooks.slack.com/services/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').with(:body => {:username => 'UserVoice', :text =>  "Peter Gibbons received *Kudos*! from Milton Waddams on <https://initech.uservoice.com/admin/tickets/22|I can't find my stapler>", :icon_url=>"https://pbs.twimg.com/profile_images/336739559/twitter_avatar_UserVoice.png"}.to_json).should have_been_made
    end
  end

  describe '#message' do
    let(:event) { "new_#{model}" }
    let(:api_xml) { fixture(event) }
    subject { Services::Slack.new(event, nil, api_xml) }

    context 'new_kudo' do
      let(:model) { :kudo }
      it 'should generate a message' do
        subject.message.should == "Peter Gibbons received *Kudos*! from Milton Waddams on <https://initech.uservoice.com/admin/tickets/22|I can't find my stapler>"
      end
    end

    context 'new_ticket' do
      let(:model) { :ticket }
      it 'should generate a message' do
        subject.message.should == "*New ticket* from Milton Waddams: <https://initech.uservoice.com/admin/tickets/22|I can't find my stapler>"
      end
    end

    context 'new_ticket_reply' do
      let(:model) { :ticket_message }
      let(:event) { 'new_ticket_reply' }
      it 'should generate a message' do
        subject.message.should == "*New ticket reply* from Milton Waddams on <https://initech.uservoice.com/admin/tickets/22|I can't find my stapler>"
      end
    end

    context 'new_suggestion' do
      let(:model) { :suggestion }
      it 'should generate a message' do
        subject.message.should == "*New idea* by Michael.Bolton: <http://initech.uservoice.com/forums/1155-initech/suggestions/7839-fax-machine-on-2nd-floor-is-broken|Fax Machine on 2nd Floor is Broken>"
      end
    end

    context 'new_comment' do
      let(:model) { :comment }
      it 'should generate a message' do
        subject.message.should == "*New comment* by @marcusnelson on <http://initech.uservoice.com/forums/1155-initech/suggestions/7843-reminder-new-coversheets-on-tps-reports|Reminder - New Coversheets on TPS Reports>"
      end
    end

    context 'new_article' do
      let(:model) { :article }
      it 'should generate a message' do
        subject.message.should == "*New article* created by Peter Gibbons: <http://initech.uservoice.com/knowledgebase/articles/98962-proper-tps-cover-report-usage|Proper TPS Cover Report Usage>"
      end
    end

    context 'new_forum' do
      let(:model) { :forum }
      it 'should generate a message' do
        subject.message.should == "*New forum*: <http://initech.uservoice.com/forums/171032-efficiency-improvements|Efficiency Improvements> created by Peter Gibbons"
      end
    end

    context 'suggestion_status_update' do
      let(:model) { :suggestion }
      let(:event) { 'suggestion_status_update' }
      it 'should generate a message' do
        subject.message.should == "*New idea status update* by Peter Gibbons on <http://initech.uservoice.com/forums/1155-initech/suggestions/7842-hawaiian-shirt-day|Hawaiian Shirt Day>"
      end
    end
  end
end

