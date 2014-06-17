###
	Node.js code for a simple server attached to a database.
	Has a console-based API that supports adding users and sending e-mails to
		'uninvited' users
	Much code was borrowed from:
		Mongoose and Express tutorials
		nodemailer quickstart
		http://pixelhandler.com/posts/develop-a-restful-api-using-nodejs-with-express-and-mongoose
			(site redirects you somewhere else if you are using Firefox)
	Most errors send back 500 and do nothing
###

###
  TODO: High Priority
    -Fix client-side requests to use AJAX (all .jade files)
    -Fix client-side invite and add requests; I messed up referencing the data (requestHandlers.coffee)
      --Change from req.param.<etc> to req.body.<etc> OR req.query.<etc> depending on if POST or GET respectively
    -Refactor serving of static content
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
bodyparser = require('body-parser')
cookieParser = require('cookie-parser')
session = require('express-session')
#mongoStore = require()
fs = require('fs')
reqHand = require('./requestHandlers')

#express and bodyparser setup
app = express()
app.use(bodyparser())
app.use(cookieParser())
app.use(session({
  name: 'app.sess'
  secret: '45df9#jk1'
}))

###
  Main routes requiring serverside processing before sending to client
###
app.route('/submit/:id')
  .get(reqHand.showUserPage)
  .post(reqHand.submitUserForm)
app.get('/admin', reqHand.showAdminCPanel)
app.post('/admin/login', reqHand.logInAdmin)
app.get('/admin/viewUsers', reqHand.showUsers)
app.post('/admin/add', reqHand.addUser)
app.post('/admin/invite', reqHand.inviteOne)
app.post('/admin/inviteall', reqHand.inviteAll)

###
  These are resource requests for js, css, or simple html files; they're small enough to be left in server.coffee
  But if we do need to do something with these requests first, then the function should be added to requestHandlers
###
# A handy function to get the resource, briefly check for errors in getting it, and spit it out to the client
giveResource = (loc) ->
  return (req, res) ->
    fs.readFile(loc, (err, data) ->
      if err
        console.error(err)
        res.send(500)
      else
        res.send(data)
    )

app.get('/semantic/semantic.css', giveResource('views/semanticui/css/semantic.min.css'))
app.get('/semantic/semantic.js', giveResource('views/semanticui/javascript/semantic.min.js'))
app.get('/admin.js', giveResource('views/admin-gui.js'))

app.listen(3000)
