###
  TODO: be able to display errors on page if they occur
    an issue because of asynchronicity, need to hook up the page somehow
  TODO: update page as db is updated
###
mongoose = require('mongoose')
jade = require('jade')
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
  status: String
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



logInAdmin = (req, res) ->
  console.log('POST admin log in with credentials ' + req.body.user + ' ' + req.body.pass)
  console.log(req)
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
    page = './views/admin-gui.jade'
  else
    page = './views/admin-login.jade'

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
	Serves user page, showing user uid and status
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
      jade.renderFile('./views/user-submit.jade',
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
  usr = User.findOneAndUpdate({'uid': req.body.uid, 'status': 'uninvited'}, {$set: {'status': 'invited'}})
  usr.exec((errQuery, usrQuery) ->
    if errQuery
      handleError(errQuery, res)
    if not usrQuery
      console.error('inviteOne: no such user or user already invited')
      res.send(400)
    else
      jade.renderFile('./views/email-invite.jade',
        {expname: 'Default', rooturl: settings.confSite.rootUrl, uid: usr._id},
        (errJade, htmlResult) ->
          if errJade
            handleError(errJade, res)
          else
            emailer.sendEmail(usr.email, 'Invitation', htmlResult)
            res.send(200)
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
      handleError(errQuery, res)
    else if usrQuery.length is 0
      console.error('inviteAll: no uninvited users')
      res.send(200)
    else
      for usr in usrQuery
        do (usr) ->
          jade.renderFile('./views/email-invite.jade',
            {expname: 'Default', rooturl: settings.confSite.rootUrl, uid: usr._id},
            (errJade, htmlResult) ->
              if errJade
                handleError(errJade, res)
              else
                emailer.sendEmail(usr.email, 'Invitation', htmlResult)
          )
          usr.status = 'invited'
          usr.save()
          res.send(200)
  )

exports.showAdminCPanel = showAdminCPanel
exports.logInAdmin = logInAdmin
exports.showUsers = showUsers
exports.showUserPage = showUserPage
exports.submitUserForm = submitUserForm
exports.addUser = addUser
exports.inviteOne = inviteOne
exports.inviteAll = inviteAll