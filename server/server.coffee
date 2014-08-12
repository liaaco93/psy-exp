###
	Node.js code for a simple server attached to a database.
	Much code was borrowed from:
		Mongoose and Express (and Express middleware) tutorials
		http://pixelhandler.com/posts/develop-a-restful-api-using-nodejs-with-express-and-mongoose
			(site redirects you somewhere else if you are using Firefox)

	Note: All paths in require use the file's current directory,
    BUT all paths not in a require call use the root directory
###

###
  TODO list:
    server.coffee
      make sessions more secure (using mongostore, maybe, just not the default)
    requestHandlers.coffee
      dynamic admin page updates (inform user of errors as they occur, update db view as db changes)
    admin-gui.jade
      fix problem with the dropdown menu and dynamic html by showing fixed number of users per "page"
        so the table is static, but its contents are dynamic
###

express = require('express')
serveStatic = require('serve-static')
bodyParser = require('body-parser')
cookieParser = require('cookie-parser')
session = require('express-session')
#mongoStore = require()
fs = require('fs')
reqHand = require('./requestHandlers')

#express setup TODO: Make sessions more secure
app = express()
app.use(bodyParser()) #interpreting JSON and HTML
app.use(cookieParser()) #sessions for login
app.use(session({
  name: 'app.sess'
  secret: '45df9#jk1'
}))
app.use('/static', serveStatic('./client')) #serving static content (includes html, css, js, css, images, fonts)

###
  Main routes requiring serverside processing before sending to client
###
app.route('/submit/:id')
  .get(reqHand.showUserPage)
  .post(reqHand.submitUserForm)
app.route('/user/login')
  .get(reqHand.showUserLogin)
  .post(reqHand.logInUser)
### TODO: figure out how users will be created first
app.route('/user/new')
  .get(reqHand.showNewUser)
  .post(reqHand.makeNewUser)
###
app.get('/', (req,res)->res.send(200))
app.get('/admin', reqHand.showAdminCPanel)
app.post('/admin/login', reqHand.logInAdmin)
app.get('/admin/viewexps', reqHand.showExperiments)
app.post('/admin/newexp', reqHand.createExperiment)
app.get('/admin/view/:eid', reqHand.expUsersTemplate)
app.get('/admin/viewusers/:eid', reqHand.showExpUsers)
app.post('/admin/adduser', reqHand.addUser)
app.post('/admin/invite', reqHand.inviteOne)
app.post('/admin/inviteall', reqHand.inviteAll)

app.listen(process.env.PORT || 5000)
