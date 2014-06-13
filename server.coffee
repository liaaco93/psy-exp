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
express = require('express')
bodyparser = require('body-parser')
fs = require('fs')
reqHand = require('./requestHandlers')

#express and bodyparser setup
app = express()
app.use(bodyparser())

###
  Main routes requiring serverside processing before sending to client
###
app.route('/submit/:id')
  .get(reqHand.showUserPage)
  .post(reqHand.submitUserForm)
app.get('/admin', reqHand.showAdminCPanel)
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
