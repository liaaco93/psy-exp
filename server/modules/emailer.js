// Generated by CoffeeScript 1.7.1
(function() {
  var mandrill, mandrill_client, sendEmail, settings;

  mandrill = require('mandrill-api/mandrill');

  settings = require('../config');

  mandrill_client = new mandrill.Mandrill(process.env.MANDRILL_APIKEY);


  /*sendEmail = (target, subj, content, callback) ->
    mailOptions =
      from: settings.confMail.content.from
      to: target
      subject: subj
      html: content
      generateTextFromHtml: true
    smtpTransport.sendMail(mailOptions, callback)
   */

  sendEmail = function(target, subj, content, success, fail) {
    var message;
    message = {
      "html": content,
      "text": "not implemented",
      "subject": subj,
      "from_email": settings.confMail.efrom,
      "from_name": settings.confMail.from,
      "to": [
        {
          "email": target
        }
      ]
    };
    return mandrill_client.messages.send({
      "message": message
    }, success, fail);
  };

  exports.sendEmail = sendEmail;

}).call(this);

//# sourceMappingURL=emailer.map
