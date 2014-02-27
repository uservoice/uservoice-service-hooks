class Services::Badgeville < Services::Base

  name "Badgeville"
  
  events_allowed %w[ new_suggestion suggestion_votes_update  ]

  string :api_key, lambda { _("API Key") }, lambda { _('You can find your API key via Badgeville Admin Console > Develop > Home. Use the Cairo key.') }
  string :site_id, lambda { _("Site ID") }, lambda { _('You can find your site ID via Badgeville Admin Console > Configure > Sites > Your Site. The ID is listed in the URL when viewing the site.') }
  boolean :production, lambda { _("Production?") }, lambda { _('Integrate with the Badgeville production environment? If unchecked, sandbox will be used.') }

  def perform
    return false if data['api_key'].blank? || data['site_id'].blank?
    host = (production) ? "api.v2.badgeville.com" : "sandbox.badgeville.com"
    request = Net::HTTP::Get.new("/cairo/v1/#{data['api_key']}/sites/#{data['site_id']}/players/#{message[:bv_email]}/activities?do=create&data=#{message[:bv_data].to_json}")
    http = Net::HTTP.new(host, 443)
    http.use_ssl = true
    response = http.request(request)
    return response.is_a?(Net::HTTPSuccess)
  end

  def message
    data = api_hash
    hash = case event
    when 'new_suggestion'
      {
        :bv_email => data['suggestion']['creator']['email'],
        :bv_data => {
          :verb => event,
          :suggestion_id => data['suggestion']['id'],
          :topic_id => data['suggestion']['topic']['id'],
          :forum_id => data['suggestion']['topic']['forum']['id'],
          :forum_name => data['suggestion']['topic']['forum']['name'],
          :category => (data['suggestion']['category'].nil?) ? "none" : data['suggestion']['category']
        }
      }
    when 'suggestion_votes_update'
      {
        :bv_email => data['suggestion']['creator']['email'],
        :bv_data => {
          :verb => event,
          :suggestion_id => data['suggestion']['id'],
          :topic_id => data['suggestion']['topic']['id'],
          :forum_id => data['suggestion']['topic']['forum']['id'],
          :forum_name => data['suggestion']['topic']['forum']['name'],
          :category => (data['suggestion']['category'].nil?) ? "none" : data['suggestion']['category'],
          :vote_count => data['suggestion']['vote_count']
        }
      }
    else
      super
    end

    hash
  end
end
