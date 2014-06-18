loadUsers = () ->
  $.get('/admin/viewusers', (data, txtStatus, jqXHR) ->
    $('#userdata').empty()
    for user in data
      $('#userdata').append(
        '<tr>\
          <td>'+user.uid+'</td>\
          <td>'+user.email+'</td>\
          <td class="ui left pointing dropdown">'+user.status+'<div class="menu"><div class="item">asdf</div></div></td>\
        </tr>'
      )
  )

$(Document).ready(()->
  $('.ui.table').hide()
  loadUsers()
  $('#userstuff').show()
)

$('.ui.dropdown').dropdown()

$('#users').click(()->
  $('.ui.table').hide()
  loadUsers()
  $('#userstuff').show()
)

$('#experis').click(()->
  $('.ui.table').hide()
  $('#experistuff').show()
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
      uid: this.uid.value
      email: this.email.value
    }
  )
  .done(()->
    $('#resultAddUsr').html("OK")
    loadUsers()
  )
  .fail((data) ->
    if data.status is 400
      $('#resultAddUsr').html("UID or e-mail already exists")
    else if data.status is 500
      $('#resultAddUsr').html("Something went wrong")
  )
  false
)