require "uri"
require "json"

class Services::Netsuite < Services::Base
  name "Netsuite"

  string   :account,  lambda { _("Account") }, lambda { _('Account number of your Netsuite site.') }
  string   :email,  lambda { _("Email") }, lambda { _('Email for the Web Services user') }
  password :password,  lambda { _("Password") }, lambda { _('Password for the Web Services user') }
  string   :role,  lambda { _("Role") }, lambda { _('Optional: Role ID to use for the Web Services user') }
  string   :external_url,  lambda { _("External URL") }, lambda { _('The URL of the RESTlet that creates a Case') }
 
  def perform
    return false if data['account'].blank?
    return false if data['email'].blank?
    return false if data['password'].blank?
    return false if data['external_url'].blank?

    subject               = api_hash['ticket']['subject']
    description           = api_hash['ticket']['url'] + "\n\n" + api_hash['ticket']['messages'].first['body']
    first_name, last_name = api_hash['ticket']['created_by']['name'].split
    email                 = api_hash['ticket']['created_by']['email']
    custom_fields         = api_hash['custom_fields']

    self.class.send_request(data, {
      "title"           => subject,
      "incomingmessage" => description,
      "firstname"       => first_name,
      "lastname"        => last_name,
      "email"           => email,
      "customfields"    => custom_fields
    })
  end

  def self.send_request(data, payload, cookie = nil)
    url = URI.parse(data['external_url'])
    request = Net::HTTP::Post.new(url.request_uri)
    request.add_field('Authorization', authorization_header(data))
    request.add_field('Content-Type', 'application/json')
    request.add_field('Cookie', cookie) if cookie
    request.body = payload.to_json
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    response = http.request(request)
    puts response.body unless response.is_a?(Net::HTTPSuccess)
    return response.is_a?(Net::HTTPSuccess)
  end

  private
  def self.authorization_header(data)
    tokens = [
      ['account',   data['account']],
      ['email',     data['email']],
      ['signature', data['password']],
      ['role',      data['role']]
    ]

    tokens.map!{ |token| token.last ? "nlauth_#{token.first}=#{token.last}" : nil }.compact!
    "NLAuth " + tokens.join(', ')
  end
end

