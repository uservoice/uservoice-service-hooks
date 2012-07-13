require 'spec_helper'

describe Services::Flowdock do
  describe 'token' do
    subject { Services::Flowdock.new(nil, @data, nil) }

    it 'should be valid' do
      @data = { 'token' => 'deadbeef123' }
      subject.valid_token?.should == true
    end

    it 'should not be valid with spaces' do
      @data = { 'token' => 'spaces not allowed in token' }
      subject.valid_token?.should == false
    end

    it 'should not be valid with a new line' do
      @data = { 'token' => "deadbeef123\n" }
      subject.valid_token?.should == false
    end
  end

  describe 'tags' do
    subject { Services::Flowdock.new(nil, nil, nil) }

    it 'should extract no tags' do
      subject.extract_tags('').should == []
    end

    it 'should extract valid tags' do
      subject.extract_tags('uservoice, feedback').should == ['uservoice', 'feedback']
    end

    it 'should extract only valid tags' do
      subject.extract_tags(", valid\ntag$123").should == ['valid', 'tag', '123']
    end
  end

  describe '#perform' do
    let(:api_xml) { fixture(:kudo) }
    let(:event) { "new_kudo" }
    let(:token) { 'deadbeef123' }
    let(:tags) { 'uservoice' }
    let(:data) { { 'token' => token, 'tags' => 'uservoice' } }
    let(:message) { MultiJson.decode() }
    let(:stub_url) { "https://api.flowdock.com:443/uservoice/#{token}.json" }

    before { stub_request(:post, stub_url) }

    it 'should post to flowdock' do
      hook = Services::Flowdock.new(event, data, api_xml)
      body = URI.encode_www_form({'data' => hook.message_data, 'event' => event})
      hook.perform
      a_request(:post, stub_url).with(:body => body).should have_been_made
    end
  end

  describe '#message' do
    subject { Services::Flowdock.new(event, nil, api_xml) }

    {
      'new_article' => 'article',
      'new_comment' => 'comment',
      'new_forum' => 'forum',
      'new_kudo' => 'kudo',
      'new_suggestion' => 'suggestion',
      'new_ticket' => 'ticket',
      'new_ticket_reply' => 'ticket_message',
      'suggestion_status_update' => 'suggestion'
    }.each do |event, _fixture|
      context event do
        let(:event) { event }
        let(:api_xml) { fixture(_fixture) }
        it "should generate a message" do
          subject.message.should == Hash.from_xml(api_xml).values.first
        end
      end
    end
  end
end
