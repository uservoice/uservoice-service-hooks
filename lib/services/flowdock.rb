require 'multi_json'

class Services::Flowdock < Services::Base
  name "Flowdock"
  string :token, lambda { _("Flow token") }, lambda { _('Get your flow token at https://www.flowdock.com/account/tokens and select a flow from the dropdown.') }
  string :tags, lambda { _("Tags") }, lambda { _('Comma separated string, eg. "uservoice, feedback" gets tagged with #uservoice and #feedback in Flowdock.') }

  def perform
    return false unless valid_token?

    request = Net::HTTP::Post.new("/uservoice/#{data['token']}.json")
    request.set_form_data('data' => message_data, 'event' => event)

    http = Net::HTTP.new("api.flowdock.com", 443)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    response = http.request(request)
    return response.is_a?(Net::HTTPSuccess)
  end

  def message_data
    tags = extract_tags(data['tags']) || []
    MultiJson.encode(message.merge('tags' => tags))
  end

  def valid_token?
    !!(data['token'] =~ /\A[a-z0-9]+\z/)
  end

  def extract_tags(str)
    str.split(/\W/).select{|s| s.strip.size > 0}.map(&:downcase).uniq
  end

  def message
    data = api_hash
    case event
      when 'new_kudo', 'new_ticket', 'new_ticket_reply', 'new_suggestion', 'new_comment', 'new_article', 'new_forum', 'suggestion_status_update'
        data
      else
        { 'message' => super }
    end
  end

end
