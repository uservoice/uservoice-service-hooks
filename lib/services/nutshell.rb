class Services::Nutshell < Services::Base
  service_name "Nutshell"
  events_allowed %w[ new_ticket new_ticket_reply new_ticket_admin_reply new_ticket_note]

  string  :api_key,  lambda { _("API Key") }, lambda { _('API Key for Nutshell account'), lambda { _('See %{link}') % {:link => '<a href="https://app.nutshell.com/setup/api-key/uservoice">https://app.nutshell.com/setup/api-key/uservoice</a>'.html_safe} }

  def perform
    return false if data['api_key'].blank?

    nut_endpoint = "https://app.nutshell.com/api/v1/public/uservoice/#{data['api_key'].strip}"

    uri = URI.parse(nut_endpoint)

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
