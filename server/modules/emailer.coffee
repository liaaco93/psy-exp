mandrill = require('mandrill-api/mandrill')
#nodemailer = require('nodemailer')
settings = require('../config')

#nodemailer setup
#smtpTransport = nodemailer.createTransport(settings.confMail.smtp)
#deprecating nodemailer so we can use heroku's mandrill
mandrill_client = new mandrill.Mandrill(process.env.MANDRILL_APIKEY)

###sendEmail = (target, subj, content, callback) ->
  mailOptions =
    from: settings.confMail.content.from
    to: target
    subject: subj
    html: content
    generateTextFromHtml: true
  smtpTransport.sendMail(mailOptions, callback)

###

sendEmail = (target, subj, content, success, fail) ->
  message = {
    "html": content,
    "text": "not implemented",
    "subject": subj,
    "from_email": settings.confMail.efrom,
    "from_name": settings.confMail.from,
    "to": [{
      "email": target
    }]
  }
  mandrill_client.messages.send({"message": message},
    success,
    fail
  )
exports.sendEmail = sendEmail