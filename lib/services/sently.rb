# require 'uri'
# require 'openssl'
# require 'net/http'

class Services::Sently < Services::Base
  name "Sent.ly"
  events_allowed %w[ new_ticket_admin_reply ]

  def perform
    uri = URI.parse("https://sent.ly/uservoice/updatehandler")
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	request = Net::HTTP::Post.new(uri.path)
	request["Content-Type"] = "application/x-www-form-urlencoded"
	request.body = "data=" + message
	response = http.request(request)
    return response.is_a?(Net::HTTPSuccess)
  end

  def message
    api_hash.to_json
  end
end