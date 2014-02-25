class Services::Badgeville < Services::Base

  name "Badgeville"
  
  events_allowed %w[ new_suggestion suggestion_votes_update  ]

  string :api_key, lambda { _("API Key") }, lambda { _('You can find your API key via Badgeville Admin Console > Develop > Home. Use the Cairo key.') }
  string :site_id, lambda { _("Site ID") }, lambda { _('You can find your site ID via Badgeville Admin Console > Configure > Sites > Your Site. The ID is listed in the URL when viewing the site.') }
  boolean :production, lambda { _("Production?") }, lambda { _('Integrate with Badgeville's production environment? If unchecked, sandbox will be used.') }

  def perform
    return false if data['api_key'].blank? || data['site_id'].blank?
    host = (production) ? "api.v2.badgeville.com" : "sandbox.badgeville.com"
    request = Net::HTTP::Get.new("/cairo/v1/#{data['api_key']}/sites/#{data['site_id']}/players/#{message[:activity][:actor]['email']}/activities?do=create&data={verb:'#{event}'}")
    http = Net::HTTP.new(host, 443)
    http.use_ssl = true
    response = http.request(request)
    return response.is_a?(Net::HTTPSuccess)
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
    when 'suggestion_votes_update'
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
