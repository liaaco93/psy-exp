###
	Node.js code for a simple server attached to a database.
	Has a console-based API that supports adding users and sending e-mails to
		'uninvited' users
	Much code was borrowed from:
		Mongoose and Express tutorials
		nodemailer quickstart
		http://pixelhandler.com/posts/develop-a-restful-api-using-nodejs-with-express-and-mongoose
			(site redirects you somewhere else if you are using Firefox)
	Currently all (except one) errors send "I'm a teapot", error code 418, back
###

express = require('express')
mongoose = require('mongoose')
bodyparser = require('body-parser')
nodemailer = require('nodemailer')

#DB setup
mongoose.connect('mongodb://localhost/test')
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

#function for more clearly querying by ObjectId from String id
queryId = (id) ->
	objectId = mongoose.Types.ObjectId(id)
	{'_id': objectId}


#nodemailer setup
#remember to fill in your own user and pass
#there is also the option for sending without SMTP?
smtpTransport = nodemailer.createTransport("SMTP",{
	service: "Gmail",
	auth: {
		user: "<your-email-here>",
		pass: "<your-password-here>"
	}
})
mailOptions = {
	from: "Test Bot <lc73571n9@gmail.com>",
	to: "",
	subject: "Invitation Link",
	text: ""
}

#express and bodyparser setup
app = express()
app.use(bodyparser())

###
	Handles showing user pages and form submission.
	Just shows users their uid and status;
	submission changes user status to 'completed'
###
#needs templating so we can easily change contents of pages
#instead of this ugly hardcoded html
app.route('/submit/:id')
.get((req, res) ->
	console.log('GET request from ' + req.params.id)
	usr = User.findById(queryId(req.params.id))
	usr.select('uid status')
	usr.exec((err, usrQuery) ->
		if err
			console.error(err)
		else if not usrQuery
			console.error('error in user page: _id not found')
		else
			body =\
				'<html>\
					<head></head>\
					<body><p>Welcome ' + usrQuery.uid + '!</p>\
						<p>Your current status is ' + usrQuery.status + '.</p>\
					</body>\
					<form method="post">\
						<input type="submit" value="SUBMIT"/>\
					</form>
				</html>'

		if err or not usrQuery
			body =\
				'<html>\
					<head></head>\
					<body>Sorry, something went wrong: \
						User does not exist.</body>\
				</html>'

		res.set('Content-Type', 'text/html')
		res.send(body)))
.post((req, res) ->
	console.log('POST request from ' + req.params.id)
	User.findByIdAndUpdate(queryId(req.params.id), {'$set': {'status': 'completed'}}, (err, usrQuery) ->
		if err
			console.error(err)
			res.send(418)
		else if not usrQuery
			console.error('error in user submit: _id not found')
		else  
			console.log('uid: ' + usrQuery.uid + ' status: ' + usrQuery.status)
	)
	res.send(200))

###
	JQuery console-based API from:
	http://pixelhandler.com/posts/develop-a-restful-api-using-nodejs-with-express-and-mongoose
	Commands (using relative paths from /api):
		POST add   uid: a number, email: a string
		POST invite   uid: a number
		POST inviteall   no json needed
###
app.get('/api', (req, res) ->
	console.log('GET: api')
	res.send('<html><head></head><body><p>API up, args in JSON.</p> \
		<p>POST: ./add(uid,email), ./invite(uid), ./inviteall()</p>\
		<script src="http://cdnjs.cloudflare.com/ajax/libs/jquery/1.7.1/jquery.min.js"></script></body></html>'))

#Adding a new user
app.post('/api/add', (req, res) ->
	console.log('POST: add user uid:' + req.body.uid + ' email:' + req.body.email)
	User.findOne({'$or': [{'uid': req.body.uid}, {'email': req.body.email}]}, (err, usrQuery) ->
		if err
			console.error(err)
			res.send(418)
		else if usrQuery
			console.error('error in /api/add: uid or email already exists')
		else
			usr = new User({
				'uid': req.body.uid,
				'email': req.body.email,
				'status': 'uninvited'})
			usr.save((err) ->
				if err
					console.error(err)
					res.send(418)
				else
					console.log('/api/add: added uid ' + req.body.uid)
					res.send(201)
			)
	)
)

#Inviting one uid
app.post('/api/invite', (req, res) ->
	console.log('POST: invite user uid:' + req.body.uid)
	usr = User.findOneAndUpdate({'uid': req.body.uid, 'status': 'uninvited'}, {$set: {'status': 'invited'}})
	usr.select('_id email')
	usr.exec((err, usrQuery) ->
		if err
			console.error(err)
			res.send(418)
		if not usrQuery
			console.error('error in /api/invite: no such user or user already invited')
			res.send(418)
		else
			mailOptions.to = usrQuery.email
			mailOptions.text = "Here is your url: http://localhost:3000/submit/" + usrQuery._id
			smtpTransport.sendMail(mailOptions, (errmail, response) ->
				if errmail
					console.error(errmail)
					res.send(418)
				else
					console.log('/api/invite: sent to ' + usrQuery.email)
					res.send(200)
			)
	)
)

#Inviting all uninvited uids
app.post('/api/inviteall', (req, res) ->
	console.log('POST: invite all uninvited')
	usrs = User.find({'status': 'uninvited'})
	usrs.exec((err, usrQuery) ->
		if err
			console.error(err)
			res.send(418)
		else if usrQuery.length is 0
			console.log('/api/inviteall: no uninvited users')
		else
			for usr in usrQuery
				do (usr) ->
					mailOptions.to = usr.email
					mailOptions.text = "Here is your url: http://localhost:3000/submit/" + usr._id
					usr.status = 'invited'
					usr.save(
						smtpTransport.sendMail(mailOptions, (errmail, response) ->
							if errmail
								console.error(errmail)
								res.send(418)
							else
								console.log('/api/inviteall: e-mail sent to ' + usr.email)
						)
					)
		res.send(200)
	)
)

app.listen(3000)
