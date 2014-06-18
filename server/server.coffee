###
	Node.js code for a simple server attached to a database.
	Much code was borrowed from:
		Mongoose and Express (and Express middleware) tutorials
		http://pixelhandler.com/posts/develop-a-restful-api-using-nodejs-with-express-and-mongoose
			(site redirects you somewhere else if you are using Firefox)

	Warning: All paths in require use the file's current directory,
    BUT all paths not in a require call use the root directory
###

###
  TODO: High Priority
    -Fix client-side requests to use AJAX (all .jade files)
    -Fix client-side invite and add requests; I messed up referencing the data (requestHandlers.coffee)
      --Change from req.param.<etc> to req.body.<etc> OR req.query.<etc> depending on if POST or GET respectively
  TODO: Medium Priority
    -Figure out how secure login is and how to make more secure
    -Clean up and prettify .jade pages, implement reusable templates for sidebars, headers, etc
    -???
  TODO: Low Priority / Optional
    -Set up user pages to view available experiments, change settings etc?
    -Design .jade pages from ground up to be more functional
    -Set up hub page so it's easier to get around (so can move easily between main page and admin,
      or userpage and experiment page)
###

express = require('express')
serveStatic = require('serve-static')
bodyParser = require('body-parser')
cookieParser = require('cookie-parser')
session = require('express-session')
#mongoStore = require()
fs = require('fs')
reqHand = require('./requestHandlers')

#express setup
app = express()
app.use(bodyParser()) #interpreting JSON and HTML
app.use(cookieParser()) #sessions for login
app.use(session({
  name: 'app.sess'
  secret: '45df9#jk1'
}))
app.use('/static', serveStatic('./client')) #serving static content

###
  Main routes requiring serverside processing before sending to client
###
app.route('/submit/:id')
  .get(reqHand.showUserPage)
  .post(reqHand.submitUserForm)
app.get('/admin', reqHand.showAdminCPanel)
app.post('/admin/login', reqHand.logInAdmin)
app.get('/admin/viewusers', reqHand.showUsers)
app.post('/admin/adduser', reqHand.addUser)
app.post('/admin/invite', reqHand.inviteOne)
app.post('/admin/inviteall', reqHand.inviteAll)

app.listen(3000)
