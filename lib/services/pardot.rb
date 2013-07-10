class Services::Pardot < Services::Base
  name "Pardot"
  events_allowed %w[ new_suggestion new_ticket new_ticket_reply new_ticket_admin_reply new_suggestion new_comment new_kudo new_article new_forum suggestion_status_update ]
  string :account_id, lambda { _('Account ID') }, lambda { _('Pardot account identifier') }
  string :request_hash, lambda { _('Request Hash') }, lambda { _('Request hash') }

  def perform
    uri = begin
            URI.parse("https://pi.pardot.com/uv/#{data['account_id'].strip}/#{data['request_hash'].strip}")
          rescue URI::InvalidURIError
            return false
          end

    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"] = "application/json"
    request.body = message

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    response = http.request(request)
    return response.is_a?(Net::HTTPSuccess)
  end

  def message
    api_hash.to_json
  end
end