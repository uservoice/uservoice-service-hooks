require "uri"
require "json"

class Services::Netsuite < Services::Base
  name "Netsuite"

  string :account,  lambda { _("Account") }, lambda { _('TODO') }
  string :email,  lambda { _("Email") }, lambda { _('TODO') }
  string :password,  lambda { _("Password") }, lambda { _('TODO') }
  string :role,  lambda { _("Role") }, lambda { _('TODO') }
  string :external_url,  lambda { _("External URL") }, lambda { _('RESTlet URL') }
 
  def perform
    # TODO: better validation
    return false if data['account'].blank?
    return false if data['email'].blank?
    return false if data['password'].blank?
    return false unless data['role'] =~ /^\d+$/
    return false if data['external_url'].blank?

    url = URI.parse(data['external_url'])
    authorization = "NLAuth nlauth_account=#{data['account']}, nlauth_email=#{data['email']}, nlauth_signature=#{data['password']}, nlauth_role=#{data['role']}"

    # TODO: get description
    ticket_data = {
      "subject"     => api_hash['ticket']['subject'],
      "description" => api_hash['ticket']['messages'].first['body'],
      "name"        => api_hash['ticket']['created_by']['name'],
      "email"       => api_hash['ticket']['created_by']['email'],
      "ticket_url"  => api_hash['ticket']['url']
    }

    request = Net::HTTP::Post.new(url.path)
    request.add_field('Authorization', authorization)
    request.add_field('Content-Type', 'application/json')
    request.body = ticket_data.to_json
    http = Net::HTTP.new(url.host, url.port)
    response = http.request(request)
    return response.is_a?(Net::HTTPSuccess)
  end
end

