###
  TODO: be able to display errors on page if they occur
    an issue because of asynchronicity, need to hook up the page somehow
  TODO: update page as db is updated
###
mongoose = require('mongoose')
jade = require('jade')
crypto = require('crypto')
emailer = require('./modules/emailer')
settings = require('./config')

#DB setup
mongoose.connect(settings.confSite.dbUrl)
db = mongoose.connection
db.on('error', console.error.bind(console, 'connection error:'))
db.once('open', callback = ()->)

###
	Schema/model for users:
	uid: should be unique, but we can use ObjectID
		from the DB as a unique identifier; no checking
		of uniqueness currently in uid
	email: again, should be unique, we don't want multiple
		users all with the same email; again, no checking of
		uniqueness yet
	status: one of 'uninvited', 'invited', or 'completed'
###
userSchema = mongoose.Schema({
  uid: Number,
  email: String,
  status: String,
  hashedPassword: String
})
User = mongoose.model('users', userSchema);

#function for querying by ObjectId from String id
queryId = (id) ->
  objectId = mongoose.Types.ObjectId(id)
  {'_id': objectId}

#rudimentary error handling; expected to be deprecated
handleError = (err, res) ->
  console.error(err)
  res.send(500)

###
  Start of User functions
###
showUserLogin = (req, res) ->
  console.log('GET user login page')
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
  console.log('POST attempting to log in ' + req.params.uid)
  hashedPass = crypto.createHash('sha512')
  hashedPass.update(req.params.pass, 'ascii')
  #TODO: implement accepted crypto practices: iterate over hash min 1000 times, use random salt to protect db
  User.findOne({uid: req.params.uid, hashedPassword: hashedPass.digest('hex')},
    (errQuery, usrQuery) ->
      if errQuery
        handleError(errQuery, res)
      else if not usrQuery
        console.error('logInUser: invalid uid or pass')
        res.send(400)
      else
        #TODO: actually implement changing the session to reflect user login
        res.send(200)
  )

###
	Serves user's experiment page, showing user uid and status
###
showUserPage = (req, res) ->
  console.log('GET request from ' + req.params.id)
  usr = User.findById(queryId(req.params.id))
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
  Updates user status
###
submitUserForm = (req, res) ->
  console.log('POST request from ' + req.params.id)
  User.findByIdAndUpdate(queryId(req.params.id),
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
###
logInAdmin = (req, res) ->
  console.log('POST admin log in with credentials ' + req.body.user + ' ' + req.body.pass)
  if req.body.pass is settings.confSite.adminUser[req.body.user]
    req.session.name = req.body.user
    res.send(200)
  else
    res.send(400)

###
  Show admin page
###
showAdminCPanel = (req, res) ->
  console.log('GET view admin control panel')

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
  Returns full table of users
###
showUsers = (req, res) ->
  console.log('GET view user table')
  User.find({}, 'uid email status', (errQuery, doc) ->
    if errQuery
      handleError(errQuery, res)
    else
      res.send(doc)
  )

###
  Adds one user using fields {uid, email}
###
addUser = (req, res) ->
  console.log('POST add user uid:' + req.body.uid + ' email:' + req.body.email)
  User.findOne({'$or': [{'uid': req.body.uid}, {'email': req.body.email}]},
    (errQuery, usrQuery) ->
      if errQuery
        handleError(errQuery, res)
      else if usrQuery
        console.error('addUser: uid or email already exists')
        res.send(400)
      else
        usr = new User({
          'uid': req.body.uid,
          'email': req.body.email,
          'status': 'uninvited'})
        usr.save((errSave) ->
          if errSave
            handleError(errSave, res)
          else
            console.log('addUser succeeded')
            res.send(200)
        )
  )

###
  Sends an e-mail to uninvited user indicated by uid
  Updates status to invited
###
inviteOne = (req, res) ->
  console.log('POST invite ' + req.body.uid)
  usr = User.find({'uid': req.body.uid, 'status': 'uninvited'})
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
  console.log('POST: invite all uninvited')
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
exports.showUsers = showUsers
exports.addUser = addUser
exports.inviteOne = inviteOne
exports.inviteAll = inviteAll