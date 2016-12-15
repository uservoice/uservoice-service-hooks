class Services::Campfire < Services::Base
  service_name "GetBadges"
  events_allowed %w[ new_ticket new_ticket_reply new_ticket_admin_reply new_suggestion new_comment new_kudo new_article new_forum new_user_story suggestion_status_update suggestion_votes_update ]
  string :token, lambda { _("GetBadges integration token") }, lambda { _('Find your auth token at your game in getbadges.io') }

  def perform
    return false unless data['token'].blank?
    request = Net::HTTP::Post.new("/api/app/webhook/" + data['token'])
    request.body = { data: api_hash, event: event }.to_json
    request.content_type = 'application/json'
    http = Net::HTTP.new("https://getbadges.io", 443)
    http.use_ssl = true
    response = http.request(request)
    response.is_a?(Net::HTTPSuccess)
  end
end
