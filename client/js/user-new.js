// Generated by CoffeeScript 1.7.1
(function() {
  $('#newUser').submit(function() {
    console.log({
      email: this.email.value,
      pass: this.passwrd.value,
      age: this.age.value,
      gender: this.gender.value,
      ethnicity: this.ethnicity.value
    });
    $.post('/newuser', {
      email: this.email.value,
      pass: this.passwrd.value,
      age: this.age.value,
      gender: this.gender.value,
      ethnicity: this.ethnicity.value
    }).done(function(data) {
      return console.log("OK");
    }).fail(function(data) {
      return console.log("FAIL " + data.status);
    });
    return false;
  });

}).call(this);

//# sourceMappingURL=user-new.map