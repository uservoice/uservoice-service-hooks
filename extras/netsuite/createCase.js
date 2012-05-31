/*
  This RESTlet should be deployed to your Netsuite site. It handles the payload
  delivered by the UserVoice service hook and creates a new Case. The URL of
  the RESTlet should be entered in the External URL field of the service hook
  entry form.

  You may need to change WEB_ORIGIN to the appropriate ID.

  If you have custom fields that you want to set, create a script with a
  "setOtherCaseFields" function and set as a Library script for this RESTlet
  in Netsuite. The setOtherCaseFields function will be called with the new
  Case record and the payload data. The custom fields data is
  in data['customfields'].
*/

function createCase(data) {
  if (!data.title || !data.incomingmessage || !data.email) {
    return false;
  }

  var WEB_ORIGIN = -5;

  var record = nlapiCreateRecord('supportcase');
  record.setFieldValue('title', data.title);
  record.setFieldValue('incomingmessage', data.incomingmessage);
  record.setFieldValue('email', data.email);
  record.setFieldValue('origin', WEB_ORIGIN);

  if (data.firstname && data.lastname) {
    var contact = findOrCreateContact(data.email, data.firstname, data.lastname);

    if (contact) {
      record.setFieldValue('contact', contact.getID());
    }
  }

  if (setOtherCaseFields) {
    setOtherCaseFields(record, data);
  }

  nlapiSubmitRecord(record, true, true);
  return true;
}

function findOrCreateContact(email, firstname, lastname) {
  var contact = null;

  try {
    var contacts = nlapiSearchDuplicate('contact', {email:email, firstname:firstname, lastname:lastname});

    if (contacts && contacts.length > 0) {
      contact = contacts[0];
    } else {
      var contact = nlapiCreateRecord('contact');
      contact.setFieldValue('email', email);
      contact.setFieldValue('firstname', firstname);
      contact.setFieldValue('lastname', lastname);
      nlapiSubmitRecord(contact, true, true);
    }
  } catch(err) {
    // If we don't have proper permissions for contact search and/or creation, we will end up here
  }

  return contact;
}