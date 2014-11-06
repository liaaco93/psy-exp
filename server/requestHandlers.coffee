###
  TODO: be able to display errors on page if they occur
    an issue because of asynchronicity, need to hook up the page somehow
  TODO: update page as db is updated
###
mongoose = require('mongoose')
jade = require('jade')
crypto = require('crypto')
_ = require('underscore')
Q = require('q')
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
  Adds a new user to the db
  TODO: hash password
  TODO: verify field inputs
  TODO: check if referral, so can auto-add exp
###
createUser = (req, res) ->
  console.log("POST creating user from #{req.body.email}")
  hashedPass = crypto.createHash('sha512')
  hashedPass.update(req.body.pass, 'ascii')
  User.create(
    {
      email: req.body.email,
      hashedPassword: hashedPass.digest('hex'),
      demographics: {
        age: req.body.age,
        gender: req.body.gender,
        ethnicity: req.body.ethnicity
      }
    }, (saveErr, usr)->
      if saveErr
        handleError(saveErr, res)
      else
        console.log(usr)
        res.send(200)
  )
###
	Serves user's experiment page, showing user uid and status
###
showUserPage = (req, res) ->
  console.log("GET request from #{req.params.hashstring}")
  Experiment.findOne(
    {'users.link': req.params.hashstring},
    (errQuery, query) ->
      if errQuery
        handleError(errQuery, res)
      else if not query
        console.error('showUserPage: hash not found')
        res.send(404)
      else
        i = 0
        found = false
        while (i < query.users.length) and (not found)
          if query.users[i].link = req.params.hashstring
            target = query.users[i]
            found = true
          i++
        if (target is undefined or target.linkExpiry is undefined)
          console.error('showUserPage: something strange happened')
          res.send(500)
          return
        else if ((new Date(target.linkExpiry)).getTime() < (new Date()).getTime())
          console.error('showUserPage: link expired')
          res.send(400, 'link expired')
        else
          jade.renderFile('server/views/user-submit.jade',
            {uid: target.uid, status: target.status},
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
    invites a user
    invites all users
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
            expQuery.users.push({
              'uid': req.body.uid,
              'email': req.body.email,
              'status': 'uninvited',
              'link': "WHY",
              'linkExpiry': Date(),
              'data': {}
            })
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
  Generates the experiment link hash for the user.
  hash is a hash of:
    experiment object id
    user id
    expiry date
  Is a separate function in case link format should change, like if there would be performance improvements to having
  some data explicit in the link or we need to add/remove info to/from the hash.
###
generateExpLink = (expObjId, uid, expiryDate) ->
  unifiedString = "" + expObjId + uid + expiryDate
  hashed = crypto.createHash('sha1')
  hashed.update(unifiedString, 'ascii')
  return(hashed.digest('hex'))

###
  Sends an e-mail to uninvited user indicated by uid
  Updates status to invited
###
inviteOne = (req, res) ->
  console.log("POST invite #{req.body.uid} from exp #{req.body.eid}")
  xutable = Experiment.findOne(
    {
      '_id': mongoose.Types.ObjectId(req.body.eid),
      'users.uid': req.body.uid,
      'users.status': 'uninvited' #this only restricts the query if there are NO uninvited users
    }
  )
  xutable.exec((errQuery, query) ->
    if errQuery
      handleError(errQuery, res)
    else if query.length is 0
      console.error('inviteOne: no such user or no uninvited users')
      res.send(400)
    else
      i = 0
      found = false
      while (i < query.users.length) and (not found)
        if (query.users[i].uid is parseInt(req.body.uid)) and (query.users[i].status is 'uninvited')
          target = query.users[i]
          found = true
        i++
      if (target is undefined)
        console.error('inviteOne: user already invited')
        res.send(400)
        return
      expiry = new Date()
      expiry.setDate(expiry.getDate() + query.timeLimit)
      linkhash = generateExpLink(query._id, target.uid, expiry)
      linkstring = settings.confSite.rootUrl + 'exp/' + linkhash
      jade.renderFile('server/views/email-invite.jade',
        {expname: query.name, link: linkstring},
        (errJade, htmlResult) ->
          if errJade
            handleError(errJade, res)
          else
            emailer.sendEmail(target.email, 'Invitation', htmlResult,
              (resMail) ->
                console.log(resMail)
                target.status = 'invited'
                target.linkExpiry = expiry
                target.link = linkhash
                query.save((errSave) ->
                  if errSave
                    handleError(errSave, res)
                  else
                    res.send(200)
                )
              , (errMail) ->
                handleError(errMail.message, res)
            )
      )
  )
###
  Promise-returning function to ensure that e-mails are sent and user statuses are modified
    synchronously in inviteAll
###
promiseInvite = (expname, linkstring, email, index) ->
  deferred = Q.defer()

  jade.renderFile('server/views/email-invite.jade',
    {expname: expname, link: linkstring},
    (errJade, htmlResult) ->
      if errJade
        deferred.resolve(false)
      else
        emailer.sendEmail(email, 'Invitation', htmlResult, (errMail, resMail) ->
          if errMail
            deferred.resolve(false)
          else
            deferred.resolve(index)
        )
  )
  return deferred.promise

###
  Sends e-mails to all uninvited users
  Updates each status to invited
###

inviteAll = (req, res) ->
  console.log("POST: invite all uninvited from exp #{req.body.eid}")
  Experiment.findOne(
    {
      '_id': mongoose.Types.ObjectId(req.body.eid),
      'users.status': 'uninvited'
    },
    (errQuery, query) ->
      if errQuery
        console.error(errQuery)
        res.send(500)
      else if query is null
        console.error('inviteAll: no uninvited users')
        res.send(400)
      else
        promises = []
        linkhashes = {}
        expiry = new Date()
        expiry.setDate(expiry.getDate() + query.timeLimit)

        for u, i in query.users
          if u.status is 'uninvited'
            linkhash = generateExpLink(query._id, u.uid, expiry)
            linkstring = settings.confSite.rootUrl + 'exp/' + linkhash
            promises.push(promiseInvite(query.name, linkstring, u.email, i))
            #hopefully this will let us preserve link hashes and will be filled up synchronously
            linkhashes[i] = linkhash

        Q.all(promises)
        .then(
          (indices) ->
            deferred = Q.defer()
            for i in indices
              if i != false
                query.users[i].status = 'invited'
                query.users[i].linkExpiry = expiry
                query.users[i].link = linkhashes[i]

            query.save((errSave) ->
              if errSave
                deferred.reject(500)
              else
                deferred.resolve(200)
            )
            return deferred.promise
        )
        .done(
          ((result) -> res.send(result)),
          ((result) -> res.send(result))
        )
  )

#User stuff
exports.showUserLogin = showUserLogin
exports.logInUser = logInUser
exports.createUser = createUser
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