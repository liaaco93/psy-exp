$('#login').submit(() ->
  console.log(this.user.value)
  console.log(this.pass.value)
  $.post('/admin/login',
    {
      user: this.user.value
      pass: this.pass.value
    }
  )
  .done(()->
    $('#resultLogin').empty()
    location.reload()
  )
  .fail((data) ->
    $('#resultLogin').html('Wrong username or password')
  )
  false
)