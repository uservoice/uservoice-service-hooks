require "savon"

class Services::Netsuite < Services::Base
  name "Netsuite"

  STANDARD_CASE_FORM_ID = -100
  NS_ENDPOINT           = nil # use default

  string   :account_id,  lambda { _("Account ID") }, lambda { _('Account number of your Netsuite site.') }
  string   :email,  lambda { _("Email") }, lambda { _('Email for the Web Services user') }
  password :password,  lambda { _("Password") }, lambda { _('Password for the Web Services user') }
  string   :role,  lambda { _("Role") }, lambda { _('Optional: Role ID to use for the Web Services user') }
  string   :company_id,  lambda { _("Company ID") }, lambda { _('Company ID to use for the Case') }
 
  def perform
    return false if data['account_id'].blank? ||
                    data['email'].blank?      ||
                    data['password'].blank?   ||
                    data['company_id'].blank?

    subject               = api_hash['ticket']['subject']
    description           = api_hash['ticket']['url'] + "\n\n" + api_hash['ticket']['messages'].first['body']
    first_name, last_name = api_hash['ticket']['created_by']['name'].split
    email                 = api_hash['ticket']['created_by']['email']

    self.class.send_request(data, {
      "title"           => subject,
      "incomingMessage" => description,
      "firstName"       => first_name,
      "lastName"        => last_name,
      "email"           => email
    }, :endpoint => NS_ENDPOINT)
  end

  def self.send_request(data, fields, opts = {})
    # Set up SOAP client
    client = Savon.client do |wsdl|
      wsdl.namespace = "urn:messages_2011_2.platform.webservices.netsuite.com"
      wsdl.endpoint  = opts[:endpoint] || 'https://webservices.netsuite.com/services/NetSuitePort_2011_2'
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
      'core:account'  => data['account_id'],
      'core:email'    => data['email'],
      'core:password' => data['password']
    }

    if data['role']
      passport.merge!(
        'core:role' => {},
        :attributes! => {'core:role' => {'internalId' => data['role']}}
      )
    end

    header = {
      'wsdl:passport'    => passport,
      'wsdl:preferences' => {
        'wsdl:disableMandatoryCustomFieldValidation' => true,
        'wsdl:ignoreReadOnlyFields' => true
      }
    }

    if fields['firstName'] || fields['lastName']
      fields['incomingMessage'] = ['Name:', fields['firstName'], fields['lastName']].join(' ') + "\n" + fields['incomingMessage'].to_s
    end

    client.request :add do
      soap.input      = [:wsdl, :add]
      soap.namespaces = namespaces
      soap.header     = header
      soap.body       = {
        'wsdl:record' => {
          'lists:title'            => fields['title'],
          'lists:incomingMessage'  => fields['incomingMessage'],
          'lists:email'            => fields['email'],
          'lists:customForm'       => "",
          'lists:company'          => "",
          :attributes!             => {
            'lists:customForm' => {'internalId' => STANDARD_CASE_FORM_ID},
            'lists:company'    => {'internalId' => data['company_id'].to_i}
          }
        },
        :attributes! =>  {
          'wsdl:record' => {'xsi:type' => 'lists:SupportCase'}
        }
      }
    end
  end
end