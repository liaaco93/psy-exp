mongoose = require('mongoose')
settings = require('../config')

#DB setup
mongoose.connect(settings.confSite.dbUrl)
db = mongoose.connection
db.on('error', console.error.bind(console, 'connection error:'))
db.once('open', callback = ()->)

###
	Schema for users:
	email: again, should be unique, we don't want multiple users all with the same email
  hashedPassword: the user's password (hashed, for security)
  experiments: array of experiments the user is registered for
  demographics: demographic information, fields are self-explanatory
###
UserSchema = mongoose.Schema({
  email: String,
  hashedPassword: String,
  experiments: [Number]
  demographics: {
    age: Number,
    gender: String,
    ethnicity: String
  }
})

###
  Schema for experiments' user tables
  uid: the user taking part in the experiment
  uobjid: the entry in the main user table, if applicable
  status: any one of the following:
    uninvited: the user has not been informed of the experiment
    invited: a link has been sent for the user to complete the experiment OR
      the user has signed up for the experiment
    in progress: the user has started the experiment but not completed it
      (counted as "started" once the experiment page has been visited) /TODO: not implemented yet
    completed: the user has completed the experiment and the data has been submitted
  link: the hash in the link sent
  linkTime: the date and time when the link will expire
  data: the data received from the experiment
###
XUSchema = mongoose.Schema({
  uid: Number,
  uobjid: mongoose.Schema.Types.ObjectId,
  email: String,
  status: String,
  link: String,
  linkExpiry: Date,
  data: mongoose.Schema.Types.Mixed
})

###
  Schema for experiments:
  eid: unique identifier for experiments, used in table name for experiments' user tables
  name: the name or description for the experiment
  private: if the experiment is invite-only
  anonymous: if the user needs an account to complete the experiment
  timeLimit: how long before the invite link expires (in days), if <=0 then links never expire
  start: when the experiment is to start
  end: when the experiment is to end
###
ExperimentSchema = mongoose.Schema({
  name: String,
  private: Boolean,
  anonymous: Boolean,
  timeLimit: Number,
  start: Date,
  end: Date,
  users: [XUSchema]
})

exports.UserSchema = UserSchema
exports.ExperimentSchema = ExperimentSchema
exports.XUSchema = XUSchema