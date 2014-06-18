nodemailer = require('nodemailer')
settings = require('../config')

#nodemailer setup
smtpTransport = nodemailer.createTransport("SMTP", settings.confMail.smtp)

sendEmail = (target, subj, content) ->
  mailOptions =
    from: settings.confMail.content.from
    to: target
    subject: subj
    html: content
    generateTextFromHtml: true

  smtpTransport.sendMail(mailOptions, (error, responseStatus) ->
    if error
      console.error(error)
    else
      console.log(responseStatus.messageId)
      console.log(responseStatus.message)
  )

exports.sendEmail = sendEmail