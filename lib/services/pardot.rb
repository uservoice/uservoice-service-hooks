class Services::Pardot < Services::Base
  service_name "Pardot"
  external_setup 'The setup of the Pardot service hook is done in the Pardot connector side. See the instructions at: ' +
                 '<a target="_blank" href="http://www.pardot.com/faqs/connectors/uservoice-connector/">http://www.pardot.com/faqs/connectors/uservoice-connector/</a>'
  events_allowed %w[ new_ticket new_ticket_reply new_ticket_admin_reply new_suggestion new_comment new_kudo new_article new_forum ]
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
  rescue EOFError => e
    raise Services::HandledException.new("EOFError")
  rescue Errno::ETIMEDOUT => e
    raise Services::HandledException.new("Errno::ETIMEDOUT")
  rescue Errno::EPIPE => e
    raise Services::HandledException.new("Errno::EPIPE")
  rescue Errno::ECONNREFUSED => e
    raise Services::HandledException.new("Errno::ECONNREFUSED")
  rescue Timeout::Error => e
    raise Services::HandledException.new("Timeout::Error")
  end

  def message
    api_hash.to_json
  end
end
