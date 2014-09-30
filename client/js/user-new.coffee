$('#newUser').submit(() ->
  console.log({
    email: this.email.value,
    pass: this.passwrd.value,
    age: this.age.value,
    gender: this.gender.value,
    ethnicity: this.ethnicity.value
  })
  $.post('/newuser',
    {
      email: this.email.value,
      pass: this.passwrd.value,
      age: this.age.value,
      gender: this.gender.value,
      ethnicity: this.ethnicity.value
    }
  )
  .done((data) ->
    console.log("OK")
  )
  .fail((data) ->
    console.log("FAIL " + data.status)
  )
  false
)