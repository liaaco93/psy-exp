loadExps = () ->
  $.get('/admin/viewexps', (data, txtStatus, jqXHR) ->
    $('#experimentData').children().detach()
    for exp in data
      $('#experimentData').append("
        <tr>
          <td>#{exp.name}</td>
          <td>#{if exp.private then 'yes' else 'no'}</td>
          <td>#{if exp.anonymous then 'yes' else 'no'}</td>
          <td>#{exp.timeLimit}</td>
          <td>#{exp.start}</td>
          <td>#{exp.end}</td>
          <td><form><input type='button' id=#{exp._id} class='experi' value='goto #{exp.name}'/></td>
        </tr>"
      )
  )

$(loadExps)

$('#newExp').submit(() ->
  $.post('/admin/newexp',
    {
      name: this.name.value,
      private: this.private.checked,
      anonymous: this.anonymous.checked,
      timeLimit: this.timeLimit.value
      start: this.start.value,
      end: this.end.value
    }
  )
  .done(loadExps)
  .fail((data) ->
    console.log("FAILURE" + data.status)
  )
  false
)

$('#experimentData').on('click', '.experi', () ->
  tabMenu = $("#tabMenu", parent.document)
  tabMenu.children().removeClass("active")
  tabId = $(this).attr("id")
  if tabMenu.find("#exp\\ #{tabId}").length <= 0
    tabMenu.append(
      "<a id='exp #{$(this).attr("id")}' eid='#{$(this).attr("id")}' class='item'> #{$(this).attr('value')[5..]} </a>"
    )
  tabMenu.find("#exp\\ #{tabId}").addClass("active")
  $("#tabContents", parent.document).attr("src", "/admin/view/#{$(this).attr('id')}")
)