loadUsers = () ->
  $.get("/admin/viewusers/#{$('#userTable').attr("eid")}", (data, txtStatus, jqXHR) ->
    $('#userData').children().detach()
    console.log(data)
    for user in data.users
      $('#userData').append(
        '<tr>\
          <td>'+user.uid+'</td>\
          <td>'+user.email+'</td>\
          <td class="ui left pointing dropdown">'+user.status+'<div class="menu"><div class="item">asdf</div></div></td>\
        </tr>'
      )
    $('.ui.dropdown').dropdown()
  )

$(() ->
  loadUsers()
)

$('#invOne').submit(() ->
  $.post('/admin/invite',
    {
      uid: this.uid.value
    }
  )
  .done(()->
    $('#resultInvOne').html("OK")
    loadUsers()
  )
  .fail((data) ->
    if data.status is 400
      $('#resultInvOne').html("UID does not exist or was already invited")
    else if data.status is 500
      $('#resultInvOne').html("Something went wrong")
  )
  false
)

$('#invAll').submit(() ->
  $.post('/admin/inviteall')
  .done(()->
    $('#resultInvAll').html("OK")
    loadUsers()
  )
  .fail((data) ->
    if data.status is 400
      $('#resultInvAll').html("No uninvited users")
    else if data.status is 500
      $('#resultInvAll').html("Something went wrong")
  )
  false
)

$('#addUsr').submit(() ->
  $.post('/admin/adduser',
    {
      eid: $('#userTable').attr("eid")
      uid: this.uid.value
      email: this.email.value
    }
  )
  .done(()->
    $('#resultAddUsr').html("OK")
    loadUsers()
  )
  .fail((data) ->
    console.log(data.status)
    ###if data.status is 400
      $('#resultAddUsr').html("UID or e-mail already exists")
    else if data.status is 500
      $('#resultAddUsr').html("Something went wrong")###
  )
  false
)