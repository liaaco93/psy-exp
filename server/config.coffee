###exports.confMail =
  smtp:
    port: 587
    host: ""
    auth:
      user: ENV['MANDRILL_USERNAME']
      pass: ENV['MANDRILL_APIKEY']
  content:
    from: "Test Bot Heroku"
###
exports.confMail =
  efrom: "lc73571n9@gmail.com"
  from: "Test Bot from Heroku Mandrill"
exports.confSite =
  rootUrl: "http://evening-fortress-9193.herokuapp.com/"
  #rootUrl: "http://localhost:5000/"
  #should probably hide <dbuser> and <dbpassword> later, but for now whatever.
  dbUrl: "mongodb://admin:admin@ds031087.mongolab.com:31087/heroku_app28365881"
  #dbUrl: "mongodb://localhost/test"
  adminUser:
    "admin": "admin"