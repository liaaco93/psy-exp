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
reqHand = require('./requestHandlers')

#express and bodyparser setup
app = express()
app.use(bodyparser())

###
	JQuery console-based API from:
	http://pixelhandler.com/posts/develop-a-restful-api-using-nodejs-with-express-and-mongoose
	Commands (using relative paths from /api):
		POST add   uid: a number, email: a string
		POST invite   uid: a number
		POST inviteall   no json needed
  TODO: deprecate, make gui
###
app.get('/api', (req, res) ->
  console.log('GET: api')
  res.send('<html><head></head><body><p>API up, args in JSON.</p>
  		<p>POST: ./add(uid,email), ./invite(uid), ./inviteall()</p>
  		<script src="http://cdnjs.cloudflare.com/ajax/libs/jquery/1.7.1/jquery.min.js"></script></body></html>'))
# remember to update above with gui or something

app.route('/submit/:id')
  .get(reqHand.showUserPage)
  .post(reqHand.submitUserForm)
app.post('/api/add', reqHand.addUser)
app.post('/api/invite', reqHand.inviteOne)
app.post('/api/inviteall', reqHand.inviteAll)

app.listen(3000)
