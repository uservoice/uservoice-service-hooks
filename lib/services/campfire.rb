class Services::Campfire < Services::Base
  name "Campfire"
  string :auth_token, lambda { _("Auth token") }, lambda { _('Find your auth token at https://SUBDOMAIN.campfirenow.com/member/edit.') }
  string :subdomain, lambda { _("Subdomain") }, lambda { _('If your campfire is at https://SUBDOMAIN.campfirenow.com, enter SUBDOMAIN here.') }
  string :room, lambda { _("Room ID") }, lambda { _('If your campfire room is at https://SUBDOMAIN.campfirenow.com/room/1234, enter 1234 here.') }

  def perform
    return false unless data['subdomain'] =~ /^[\w-]+$/
    return false unless data['room'] =~ /^\d+$/
    return false if data['auth_token'].blank?
    request = Net::HTTP::Post.new("/room/#{data['room']}/speak.xml")
    request.basic_auth data['auth_token'], 'X'
    request.body = "<message><type>TextMessage</type><body>#{message}</body></message>"
    request.content_type = 'application/xml'
    http = Net::HTTP.new("#{data['subdomain']}.campfirenow.com", 443)
    http.use_ssl = true
    response = http.request(request)
    return response.is_a?(Net::HTTPSuccess)
  end

  def message
    data = api_hash
    case event
    when 'new_kudo'
      "#{data['kudo']['message']['sender']['name']} received Kudos! from #{data['kudo']['sender']['name']} on #{data['kudo']['ticket']['subject']} -- #{data['kudo']['ticket']['url']}"
    when 'new_ticket'
      "New ticket: #{data['ticket']['subject']} from #{data['ticket']['created_by']['name']} -- #{data['ticket']['url']}"
    when 'new_ticket_reply'
      "New ticket reply on #{data['ticket']['subject']} from #{data['message']['sender']['name']} -- #{data['ticket']['url']}"
    when 'new_suggestion'
      "New idea: #{data['suggestion']['title']} from #{data['suggestion']['creator']['name']} -- #{data['suggestion']['url']}"
    when 'new_comment'
      "New comment on #{data['comment']['suggestion']['title']} from #{data['comment']['creator']['name']} -- #{data['comment']['suggestion']['url']}"
    when 'new_article'
      "New article: #{data['article']['question']} by #{data['article']['updated_by']['name']} -- #{data['article']['url']}"
    when 'new_forum'
      "New forum: #{data['forum']['name']} created by #{data['forum']['updated_by']['name']} -- #{data['forum']['url']}"
    when 'suggestion_status_update'
      "Idea status updated: #{data['suggestion']['title']} set to #{data['suggestion']['status']['name']} by #{data['suggestion']['status_changed_by']['name']} -- #{data['suggestion']['url']}"
    else
      super
    end
  end
end

