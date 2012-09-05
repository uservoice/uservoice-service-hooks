require "savon"

class Services::Netsuite < Services::Base
  name "Netsuite"

  string   :account_id,  lambda { _("Account ID") }, lambda { _('Account number of your Netsuite site.') }
  string   :email,  lambda { _("Email") }, lambda { _('Email for the Web Services user') }
  password :password,  lambda { _("Password") }, lambda { _('Password for the Web Services user') }
  string   :role,  lambda { _("Role") }, lambda { _('Optional: Role ID to use for the Web Services user') }
  string   :company_id,  lambda { _("Company ID") }, lambda { _('Optional: Company ID to use if no matching contact found. If not provided, create new company.') }
 
  def perform
    return false if data['account_id'].blank?
    return false if data['email'].blank?
    return false if data['password'].blank?

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
    })
  end

  def self.send_request(data, fields, opts = {})
    # Set up SOAP client
    client = Savon.client do |wsdl|
      wsdl.namespace = "urn:messages_2011_2.platform.webservices.netsuite.com"
      wsdl.endpoint  = opts[:endpoint] || 'https://webservices.netsuite.com/services/NetSuitePort_2011_2'
    end

    client.config.pretty_print_xml = true
    client.config.env_namespace    = :soapenv

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

    if fields['firstName'] && fields['lastName']
      company_id = nil
      
      # Include contact info in description
      fields['incomingMessage'] = ['Name:', fields['firstName'], fields['lastName']].join(' ') + "\n" + fields['incomingMessage'].to_s

      # TODO: Find existing contact, set company_id if found

      if !company_id && !fields['company_id']
        # TODO: Create new contact if no placeholder company provided, set company_id
      end
    end

    company_id ||= fields['company_id']

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
            'lists:customForm' => {'internalId' => -100},
            'lists:company'    => {'internalId' => company_id.to_i}
          }
        },
        :attributes! =>  {
          'wsdl:record' => {'xsi:type' => 'lists:SupportCase'}
        }
      }
    end
  end
end

=begin
Sample SOAP requests

<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
  xmlns:messages="urn:messages_2011_2.platform.webservices.netsuite.com"
  xmlns:core="urn:core_2011_2.platform.webservices.netsuite.com">
      <soapenv:Header>
      <wsdl:preferences>
         <wsdl:warningAsError>false</wsdl:warningAsError>
         <wsdl:disableMandatoryCustomFieldValidation>true</wsdl:disableMandatoryCustomFieldValidation>
         <wsdl:ignoreReadOnlyFields>true</wsdl:ignoreReadOnlyFields>
      </wsdl:preferences>
      <wsdl:passport>
         <core:email>EMAIL</core:email>
         <core:password>PASSWORD</core:password>
         <core:account>ACCOUNT_ID</core:account>
         <core:role>
              <core:internalId>ROLE_ID</core:internalId>
         </core:role>
      </wsdl:passport>
   </soapenv:Header>
   <soapenv:Body>
      <wsdl:getSelectValue>
         <wsdl:fieldDescription>
            <core:recordType>supportCase</core:recordType>
            <core:field>origin</core:field>
         </wsdl:fieldDescription>
         <wsdl:pageIndex>1</wsdl:pageIndex>
      </wsdl:getSelectValue>
   </soapenv:Body>
</soapenv:Envelope>

<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
  xmlns:messages="urn:messages_2011_2.platform.webservices.netsuite.com"
  xmlns:core="urn:core_2011_2.platform.webservices.netsuite.com"
  xmlns:lists="urn:support_2011_2.lists.webservices.netsuite.com"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <soapenv:Header>
      <wsdl:preferences>
         <wsdl:warningAsError>false</wsdl:warningAsError>
         <wsdl:disableMandatoryCustomFieldValidation>true</wsdl:disableMandatoryCustomFieldValidation>
         <wsdl:ignoreReadOnlyFields>true</wsdl:ignoreReadOnlyFields>
      </wsdl:preferences>
      <wsdl:passport>
         <core:email>EMAIL</core:email>
         <core:password>PASSWORD</core:password>
         <core:account>ACCOUNT_ID</core:account>
         <core:role>
              <core:internalId>ROLE_ID</core:internalId>
         </core:role>
      </wsdl:passport>
   </soapenv:Header>
   <soapenv:Body>
      <wsdl:add>
         <wsdl:record xsi:type="lists:SupportCase">
            <lists:incomingMessage>Test message</lists:incomingMessage>
            <lists:title>Test subject</lists:title>
            <lists:email>test@example.com</lists:email>
            <lists:origin xsi:type="urn1:RecordRef">
              <core:name>Web</core:name>
              <core:internalId>-5</core:internalId>
            </lists:origin>
         </wsdl:record>
      </wsdl:add>
   </soapenv:Body>
</soapenv:Envelope>
=end