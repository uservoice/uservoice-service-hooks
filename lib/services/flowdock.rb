class Services::Flowdock < Services::Base
  service_name "Flowdock"
  events_allowed %w[ new_ticket new_ticket_reply new_ticket_admin_reply new_suggestion new_comment new_kudo new_article new_forum suggestion_status_update suggestion_votes_update ]
  string :token, lambda { _("Flow token") }, lambda { _('Get your flow token at https://www.flowdock.com/account/tokens and select a flow from the dropdown.') }
  string :tags, lambda { _("Tag(s)") }, lambda { _('The tag your events are tagged with in Flowdock. eg. "uservoice" gets tagged with #uservoice. You can use comma-seperated values here for multiple tags.') }

  def perform
    return false unless valid_token?

    request = Net::HTTP::Post.new("/uservoice/#{data['token'].strip}.json")
    request.set_form_data('data' => message_data, 'event' => event)

    http = Net::HTTP.new("api.flowdock.com", 443)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.verify_depth = 5
    response = http.request(request)

    return response.is_a?(Net::HTTPSuccess)
  end

  def message_data
    tags = extract_tags(data['tags']) || []
    message.merge('tags' => tags).to_json
  end

  def valid_token?
    !!(data['token'].strip =~ /\A[a-z0-9]+\z/)
  end

  def extract_tags(str)
    str.split(/\W/).select{|s| s.strip.size > 0}.map(&:downcase).uniq
  end

  def message
    case event
      when 'new_kudo', 'new_ticket', 'new_ticket_reply', 'new_ticket_admin_reply', 'new_suggestion', 'new_comment', 'new_article', 'new_forum', 'suggestion_status_update', 'suggestion_votes_update'
        api_hash
      else
        { 'message' => super }
    end
  end
end
