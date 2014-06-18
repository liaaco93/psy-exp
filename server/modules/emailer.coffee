nodemailer = require('nodemailer')
settings = require('../config')

#nodemailer setup
smtpTransport = nodemailer.createTransport("SMTP", settings.confMail.smtp)

sendEmail = (target, subj, content, callback) ->
  mailOptions =
    from: settings.confMail.content.from
    to: target
    subject: subj
    html: content
    generateTextFromHtml: true

  smtpTransport.sendMail(mailOptions, callback)

exports.sendEmail = sendEmail