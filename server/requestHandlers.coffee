###
  TODO: be able to display errors on page if they occur
    an issue because of asynchronicity, need to hook up the page somehow
  TODO: update page as db is updated
###
mongoose = require('mongoose')
jade = require('jade')
crypto = require('crypto')
_ = require('underscore')
emailer = require('./modules/emailer')
dbSchemata = require('./modules/dbSetup')
settings = require('./config')

#DB tables/models setup
User = mongoose.model('users', dbSchemata.UserSchema)
Experiment = mongoose.model('experiments', dbSchemata.ExperimentSchema)

#rudimentary error handling; expected to be deprecated
handleError = (err, res) ->
  console.error(err)
  res.send(500)

###
  Start of User functions:
    show user login page
    log in user
    show user experiment page
    handle data from user experiment page submission
###

###
  Serves user login page /TODO: no such page
###
showUserLogin = (req, res) ->
  console.log("GET user login page")
  jade.renderFile('server/views/user-login.jade', {},
    (errJade, htmlResult) ->
      if errJade
        handleError(errJade, res)
      else
        res.send(htmlResult)
  )

###
  Logs in user
###
logInUser = (req, res) ->
  console.log("POST attempting to log in #{req.params.uid}")
  hashedPass = crypto.createHash('sha512')
  hashedPass.update(req.params.pass, 'ascii')
  #TODO: implement accepted crypto practices: iterate over hash min 1000 times, use random salt to protect db
  Users.findOne({uid: req.params.uid, hashedPassword: hashedPass.digest('hex')},
    (errQuery, usrQuery) ->
      if errQuery
        handleError(errQuery, res)
      else if not usrQuery
        console.error('logInUser: invalid uid or pass')
        res.send(400)
      else
        #TODO: implement actually changing the session to reflect user login
        res.send(200)
  )

###
	Serves user's experiment page, showing user uid and status
###
showUserPage = (req, res) ->
  console.log("GET request from #{req.params.id}")
  usr = User.findById(mongoose.Types.ObjectId(req.params.id))
  usr.exec((errQuery, usrQuery) ->
    if errQuery
      handleError(errQuery, res)
    else if not usrQuery
      console.error('showUserPage: _id not found')
      res.send(404)
    else
      jade.renderFile('server/views/user-submit.jade',
        {uid: usrQuery.uid, status: usrQuery.status},
        (errJade, htmlResult) ->
          if errJade
            handleError(errJade, res)
          else
            res.send(htmlResult)
      )
  )

###
  Handles experiment page submission, currently only updates user status
###
submitUserForm = (req, res) ->
  console.log("POST request from #{req.params.id}")
  User.findByIdAndUpdate(mongoose.Types.ObjectId(req.params.id),
    {'$set': {'status': 'completed'}},
    (errQuery, usrQuery) ->
      if errQuery
        handleError(errQuery, res)
      else if not usrQuery
        console.error('submitUserForm: _id not found')
        res.send(404)
      else
        console.log('uid: ' + usrQuery.uid + '| status: ' + usrQuery.status)
        res.send(200)
  )


###
  Start of Admin functions
    log in admin
    show admin page/login
    create a new experiment
    show experiment table
    show user table
    add a user
    invites a user /TODO update to use experiment's user table
    invites all users /TODO update to use experiment's user table
###

###
  Logs in the Admin
###
logInAdmin = (req, res) ->
  console.log("POST admin log in with credentials #{req.body.user} #{req.body.pass}")
  if req.body.pass is settings.confSite.adminUser[req.body.user]
    req.session.name = req.body.user
    res.send(200)
  else
    res.send(400)

###
  Show admin page
###
showAdminCPanel = (req, res) ->
  console.log("GET admin control panel")

  if req.session.name
    page = 'server/views/admin-gui.jade'
  else
    page = 'server/views/admin-login.jade'

  jade.renderFile(page, {},
    (errJade, htmlResult) ->
      if errJade
        handleError(errJade, res)
      else
        res.send(htmlResult)
  )

###
  Creates a new experiment
###
createExperiment = (req, res) ->
  console.log("POST new experiment")
  console.log(req.body)
  Experiment.create(
    {
      name: req.body.name,
      private: if req.body.private is 'true' then true else false,
      anonymous: if req.body.anonymous is 'true' then true else false,
      timeLimit: req.body.timeLimit,
      start: new Date(req.body.start),
      end: new Date(req.body.end),
      users: []
    }, (saveErr, exp)->
      if saveErr
        handleError(saveErr, res)
      else
        console.log(exp)
        res.send(200)
  )

###
  Returns full table of experiments
###
showExperiments = (req, res) ->
  console.log("GET experiments table")
  Experiment.find({}, (errQuery, doc) ->
    if errQuery
      handleError(errQuery, res)
    else
      res.send(doc)
  )

###
  Renders the Jade page for the user table of an experiment
###
expUsersTemplate = (req, res) ->
  console.log("GET page for experiment #{req.params.eid}")
  jade.renderFile("server/views/admin-gui-usertable.jade", {eid: req.params.eid},
    (errJade, htmlResult) ->
      if errJade
        handleError(errJade, res)
      else
        res.send(htmlResult)
    )

###
  Queries db for users in an experiment
###
showExpUsers = (req, res) ->
  console.log("GET users from experiment #{req.params.eid}")
  Experiment.findById(mongoose.Types.ObjectId(req.params.eid), "users",
    (errExpQuery, expQuery) ->
      if errExpQuery
        handleError(errExpQuery, res)
      else
        console.log(expQuery.users)
        res.send(expQuery)
  )

###
  Adds one user using fields {uid, email}
###
addUser = (req, res) ->
  console.log("POST add user uid:#{req.body.uid} email:#{req.body.email} to exp #{req.body.eid}")
  Experiment.find(
    {
      '_id': mongoose.Types.ObjectId(req.body.eid),
      '$or': [
        {'users.uid': req.body.uid},
        {'users.email': req.body.email}
      ]
    },
    (errQuery, usrQuery) ->
      if errQuery
        handleError(errQuery, res)
      else if usrQuery.length
        console.error('addUser: uid or email already exists')
        res.send(400)
      else
        Experiment.findById(mongoose.Types.ObjectId(req.body.eid), (errExpQuery, expQuery) ->
          if errExpQuery
            handleError(errExpQuery, res)
          else
            expQuery.users.push({'uid': req.body.uid, 'email': req.body.email, 'status': 'uninvited'})
            expQuery.save((errSave, newUserDoc) ->
              if errSave
                handleError(errSave, res)
              else
                console.log("Saved #{newUserDoc}")
                res.send(200)
            )
        )
  )

###
  Sends an e-mail to uninvited user indicated by uid
  Updates status to invited
###
inviteOne = (req, res) ->
  console.log("POST invite #{req.body.uid} from exp #{req.body.eid}")
  usr = Experiment.find({
    '_id': mongoose.Types.ObjectId(req.body.eid),
    'users': {'uid': req.body.uid, 'status': 'uninvited'}})
  usr.exec((errQuery, usrQuery) ->
    if errQuery
      handleError(errQuery, res)
    else if not usrQuery
      console.error('inviteOne: no such user or user already invited')
      res.send(400)
    else
      jade.renderFile('server/views/email-invite.jade',
        {expname: 'Default', rooturl: settings.confSite.rootUrl, uid: usr._id},
        (errJade, htmlResult) ->
          if errJade
            handleError(errJade, res)
          else
            emailer.sendEmail(usr.email, 'Invitation', htmlResult, (errMail, resMail) ->
              if errMail
                handleError(errMail, res)
              else
                console.log(resMail)
                usr.status = 'invited'
                usr.save((errSave) ->
                  if errSave
                    handleError(errSave, res)
                )
            )
      )
  )

###
  Sends e-mails to all uninvited users
  Updates each status to invited
###
inviteAll = (req, res) ->
  console.log("POST: invite all uninvited from exp #{req.body.eid}")
  usrs = User.find({'status': 'uninvited'})
  usrs.exec((errQuery, usrQuery) ->
    if errQuery
      console.error(errQuery)
      res.send(500)
    else if usrQuery.length is 0
      console.error('inviteAll: no uninvited users')
      res.send(400)
    else
      replySent = false
      for usr in usrQuery
        jade.renderFile('server/views/email-invite.jade',
          {expname: 'Default', rooturl: settings.confSite.rootUrl, uid: usr._id},
          (errJade, htmlResult) ->
            if errJade
              console.error(errJade)
              if not replySent
                replySent = true
                res.send(500)
            else
              emailer.sendEmail(usr.email, 'Invitation', htmlResult, (errMail, resMail) ->
                if errMail
                  console.error(errMail)
                  if not replySent
                    replySent = true
                    res.send(500)
                else
                  console.log(resMail)
                  usr.status = 'invited'
                  usr.save((errSave) ->
                    if errSave
                      console.error(errSave)
                      if not replySent
                        replySent = true
                        res.send(500)
                    else if usr is usrQuery[-1..][0]
                      replySent = true
                      res.send(200)
                  )
              )
        )
  )

#User stuff
exports.showUserLogin = showUserLogin
exports.logInUser = logInUser
exports.showUserPage = showUserPage
exports.submitUserForm = submitUserForm
#Admin stuff
exports.showAdminCPanel = showAdminCPanel
exports.logInAdmin = logInAdmin
exports.showExperiments = showExperiments
exports.createExperiment = createExperiment
exports.expUsersTemplate = expUsersTemplate
exports.showExpUsers = showExpUsers
exports.addUser = addUser
exports.inviteOne = inviteOne
exports.inviteAll = inviteAll