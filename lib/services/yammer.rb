class Services::Yammer < Services::Base

  # Weird things about Yammer:
  #
  # 1. Yammer's OpenGraph implementation is extremely limited and only gives us a few
  #    verbs to work with (create, updated, delete, follow, like).
  # 2. The 'actor' in each action needs to be a person in the user's organization. If we
  #    submit an event with an external actor, Yammer invites them to join our network.
  # 3. Every event url needs to be unique or Yammer will use the title from a previous
  #    event with that url.
  #
  # So because of this we have some pretty conviluted event messages. We also need to
  # take the extra step of checking the Yammer API to see if a user exists in our
  # network. And we are appending a unique SHA1 hash to every url.

  service_name "Yammer"

  events_allowed %w[ new_suggestion new_comment new_kudo new_forum suggestion_status_update ]

  string :access_token, lambda { "Access Token" }, lambda { 'From oauth verification' }, true
  string :api_user_name, lambda { "API User Name" }, lambda { 'Name of the user who authenticated' }, true
  string :api_user_email, lambda { "API User Email" }, lambda { 'Email address of the user who authenticated' }, true
  string :api_network_name, lambda { "Yammer Network Name" }, lambda { "The name of your organization's Yammer network" }, true

  def perform
    return false if data['access_token'].blank?

    payload = message
    payload[:activity][:object][:url] += "?#{url_signature}"


    if !payload[:activity][:actor]['email']
      Rails.logger.info "this user has been deleted" #this goes to normal rails log
      return true
    end

    request = Net::HTTP::Get.new("/api/v1/users/by_email.json?email=#{CGI.escape(payload[:activity][:actor]['email'])}")
    request.add_field("Authorization", "Bearer " + data['access_token'])
    http = Net::HTTP.new("www.yammer.com", 443)
    http.use_ssl = true
    response = http.request(request)
    return expire_access_token if response.is_a?(Net::HTTPUnauthorized)

    if response.is_a? Net::HTTPNotFound
      Rails.logger.info "this bro is not in our org: #{payload[:activity][:actor]}"
      return true #this is not really a success or an error, but at least our API call worked
    end

    users = JSON.parse(response.body)
    if users && users.to_a.first.to_h['full_name']
      #use yammer's name for this person
      payload[:activity][:actor]['name'] = users[0]['full_name']
    end

    request = Net::HTTP::Post.new("/api/v1/activity.json")
    request.add_field("Authorization", "Bearer " + data['access_token'])
    request.body = payload.to_json
    request.content_type = 'application/json'
    http = Net::HTTP.new("www.yammer.com", 443)
    http.use_ssl = true
    response = http.request(request)
    return expire_access_token if response.is_a?(Net::HTTPUnauthorized)
    return response.is_a?(Net::HTTPSuccess)
  end

  def expire_access_token
    #removing the access token will force them to reauthorize the service hook in the admin
    service_hook.data['access_token'] = ''
    service_hook.save
    return false
  end

  def url_signature
    access_token = ''
    access_token = data['access_token'] if data
    Digest::SHA1.hexdigest("#{Time.now.to_f} #{access_token} #{subdomain.id}")
  end

  def generic_admin_url
    #this really sucks
    "https://#{self.subdomain.to_uservoice_host}/admin/signin"
  end

  def message
    data = api_hash
    hash = case event
    when 'test'
      {
        :activity => {
          :type => 'created',
          :actor => { 'name' => self.data[:api_user_name], 'email' => self.data[:api_user_email] },
          :action => "create",
          :object => {
            :title => "a UserVoice service hook test event",
            :object_type => "page",
            :url => "http://uservoice.com/"
          }
        }
      }
    when 'new_ticket'
      {
        :activity => {
          :type => 'created',
          :actor => data['ticket']['created_by'].slice('name', 'email'),
          :action => "create",
          :object => {
            :title => "\"#{data['ticket']['subject']}\" ticket",
            :object_type => "page",
            :url => data['ticket']['url']
          }
        }
      }
    when 'new_kudo'
      {
        :activity => {
          :type => 'created',
          :actor => data['kudo']['message']['sender'].slice('name', 'email'),
          :action => "create",
          :object => {
            # this is horrible but Yammer has an extremely limited OpenGraph implementation
            :title => "a ticket reply to \"#{data['kudo']['ticket']['subject']}\" and received Kudos",
            :object_type => "page",
            :url => data['kudo']['ticket']['url']
          }
        }
      }
    when 'new_ticket_reply'
      {
        :activity => {
          :type => 'created',
          :actor => data['message']['sender'].slice('name', 'email'),
          :action => "create",
          :object => {
            :title => "a ticket reply to \"#{data['ticket']['subject']}\"",
            :object_type => "page",
            :url => data['ticket']['url']
          }
        }
      }
    when 'new_suggestion'
      {
        :activity => {
          :type => 'created',
          :actor => data['suggestion']['creator'].slice('name', 'email'),
          :action => "create",
          :object => {
            :title => "\"#{data['suggestion']['title']}\" idea",
            :object_type => "page",
            :url => data['suggestion']['url']
          }
        }
      }
    when 'new_comment'
      {
        :activity => {
          :type => 'created',
          :actor => data['comment']['creator'].slice('name', 'email'),
          :action => "create",
          :object => {
            :title => "a comment on \"#{data['comment']['suggestion']['title']}\"",
            :object_type => "page",
            :url => data['comment']['suggestion']['url']
          }
        }
      }
    when 'new_article'
      {
        :activity => {
          :type => 'created',
          :actor => data['article']['updated_by'].slice('name', 'email'),
          :action => "create",
          :object => {
            :title => "\"#{data['article']['question']}\" article",
            :object_type => "page",
            :url => data['article']['url']
          }
        }
      }
    when 'new_forum'
      {
        :activity => {
          :type => 'created',
          :actor => data['forum']['updated_by'].slice('name', 'email'),
          :action => "create",
          :object => {
            :title => "\"#{data['forum']['name']}\" forum",
            :object_type => "page",
            :url => data['forum']['url']
          }
        }
      }
    when 'suggestion_status_update'
      status = data['audit_status']['final_status']
      status_name = (status && status['name']) || _("none")
      include_status = data['audit_status']['final_status'] != data['audit_status']['initial_status']
      {
        :activity => {
          :type => 'updated',
          :actor => data['audit_status']['user'].slice('name', 'email'),
          :action => "update",
          :object => {
            :title => "\"#{data['audit_status']['suggestion']['title']}\"#{include_status ? " to \"#{status_name}\"" : ''}",
            :object_type => "page",
            :url => data['audit_status']['suggestion']['url']
          }
        }
      }
    else
      super
    end

    hash
  end
end
