loadUsers = () ->
  $.get('/admin/viewUsers', (data, txtStatus, jqXHR) ->
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