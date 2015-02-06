class Services::Slack < Services::Base
  service_name "Slack"
  events_allowed %w[ new_ticket new_ticket_reply new_ticket_admin_reply new_suggestion new_comment new_kudo new_article new_forum suggestion_status_update suggestion_votes_update ]
  string :url_hash, lambda { _("Url Hash") }, lambda { _('See %{link}') % {:link => '<a href="https://slack.com/services/new/incoming-webhook">https://slack.com/services/new/incoming-webhook</a>'.html_safe} }

  def perform
    return false if data['url_hash'].blank?
    uri = URI.parse("https://hooks.slack.com/services/"+data['url_hash'])

    request = Net::HTTP::Post.new(uri.path)
    request.body = {
      :username => "UserVoice",
      :text => message,
      :icon_url => "https://pbs.twimg.com/profile_images/336739559/twitter_avatar_UserVoice.png" # Please overwrite with official icon
    }.to_json

    http = Net::HTTP.new(uri.host, 443)
    http.use_ssl = true
    response = http.request(request)
    return response.is_a?(Net::HTTPSuccess)
  end

  def message
    data = api_hash
    case event
    when 'new_kudo'
      "#{data['kudo']['message']['sender']['name']} received *Kudos*! from #{data['kudo']['sender']['name']} on <#{data['kudo']['ticket']['url']}|#{data['kudo']['ticket']['subject']}>"
    when 'new_ticket'
      "*New ticket* from #{data['ticket']['created_by']['name']}: <#{data['ticket']['url']}|#{data['ticket']['subject']}>"
    when 'new_ticket_reply', 'new_ticket_admin_reply'
      "*New ticket reply* from #{data['message']['sender']['name']} on <#{data['ticket']['url']}|#{data['ticket']['subject']}>"
    when 'new_suggestion'
      "*New idea* by #{data['suggestion']['creator']['name']}: <#{data['suggestion']['url']}|#{data['suggestion']['title']}>"
    when 'new_comment'
      "*New comment* by #{data['comment']['creator']['name']} on <#{data['comment']['suggestion']['url']}|#{data['comment']['suggestion']['title']}>"
    when 'new_article'
      "*New article* created by #{data['article']['updated_by']['name']}: <#{data['article']['url']}|#{data['article']['question']}>"
    when 'new_forum'
      "*New forum*: <#{data['forum']['url']}|#{data['forum']['name']}> created by #{data['forum']['updated_by']['name']}"
    when 'suggestion_status_update'
      "*New idea status update* by #{data['audit_status']['user']['name']} on <#{data['audit_status']['suggestion']['url']}|#{data['audit_status']['suggestion']['title']}>"
    when 'suggestion_votes_update'
      "*New idea votes update* on <#{data['suggestion']['url']}|#{data['suggestion']['title']}>: #{data['suggestion']['vote_count']} votes"
    else
      super
    end
  end
end

