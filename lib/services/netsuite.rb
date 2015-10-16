class Services::Netsuite < Services::Base
  service_name "Netsuite"
  beta true
  events_allowed %w[ new_ticket ]

  STANDARD_CASE_FORM_ID = -100

  NS_ENDPOINT = "https://webservices.netsuite.com/services/NetSuitePort_2011_2"
  #NS_ENDPOINT = "https://webservices.sandbox.netsuite.com/services/NetSuitePort_2011_2"

  string    :account_id,  lambda { _("Account ID") }, lambda { _('Account number of your Netsuite site.') }
  string    :email,  lambda { _("Email") }, lambda { _('Email for the Web Services user') }
  password  :password,  lambda { _("Password") }, lambda { _('Password for the Web Services user') }
  string    :role,  lambda { _("Role") }, lambda { _('Optional: Role ID to use for the Web Services user') }
  string    :company_id,  lambda { _("Company ID") }, lambda { _('Company ID to use for the Case') }

  # this is just here for testing?
  string    :endpoint,  lambda { _("Endpoint URI") }, lambda { _('API endpoint (leave blank for default)') }

  def perform
    return false if data[:account_id].blank? ||
                    data[:email].blank?      ||
                    data[:password].blank?   ||
                    data[:company_id].blank?

    send_netsuite_request(message)
  end

  def message
    hash = {}

    case event
    when 'test'
      hash = {
        title: 'Test Case from UserVoice Service Hook',
        incoming_message: 'This is just a test',
        first_name: 'User',
        last_name: 'Voice',
        email: data[:email]
      }
    when 'new_ticket'

      name = api_hash['ticket']['contact']['name']

      hash = {
        title: api_hash['ticket']['subject'],
        incoming_message: "Name: #{name}\n#{api_hash['ticket']['url']}",
        email: api_hash['ticket']['contact']['email']
      }

      # oh cool this should always work
      hash[:first_name], hash[:last_name] = name.split

      if api_hash['ticket']['messages'][0]
        hash[:incoming_message] += "\n\n" + api_hash['ticket']['messages'][0]['body']
      end
    else
      hash = super
    end

    hash
  end

  def send_netsuite_request(fields, opts = {})
    data[:endpoint] = NS_ENDPOINT if data[:endpoint].blank?

    # Set up SOAP client
    client = Savon.client do |wsdl|
      wsdl.namespace = "urn:messages_2011_2.platform.webservices.netsuite.com"
      wsdl.endpoint  = data[:endpoint]
    end

    client.config.env_namespace    = :soapenv
    client.config.log              = opts[:debug]
    client.config.pretty_print_xml = true

    namespaces = {
      'xmlns:soapenv'  => "http://schemas.xmlsoap.org/soap/envelope/",
      'xmlns:core'     => "urn:core_2011_2.platform.webservices.netsuite.com",
      'xmlns:lists'    => "urn:support_2011_2.lists.webservices.netsuite.com"
    }

    passport = {
      'core:account'  => data[:account_id],
      'core:email'    => data[:email],
      'core:password' => data[:password]
    }

    if data[:role]
      passport.merge!(
        'core:role' => {},
        :attributes! => {'core:role' => {'internalId' => data[:role]}}
      )
    end

    header = {
      'wsdl:passport'    => passport,
      'wsdl:preferences' => {
        'wsdl:disableMandatoryCustomFieldValidation' => true,
        'wsdl:ignoreReadOnlyFields' => true
      }
    }

    client.request :add do
      soap.input      = [:wsdl, :add]
      soap.namespaces = namespaces
      soap.header     = header
      soap.body       = {
        'wsdl:record' => {
          'lists:title'            => fields[:title],
          'lists:incomingMessage'  => fields[:incoming_message],
          'lists:email'            => fields[:email],
          'lists:customForm'       => '',
          'lists:company'          => '',
          :attributes!             => {
            'lists:customForm' => {'internalId' => STANDARD_CASE_FORM_ID},
            'lists:company'    => {'internalId' => data[:company_id].to_i}
          }
        },
        :attributes! =>  {
          'wsdl:record' => {'xsi:type' => 'lists:SupportCase'}
        }
      }
    end
  rescue Savon::SOAP::Fault => e
    raise Services::HandledException.new("Problem talking to NetSuite: " + e.to_s)
  end
end
