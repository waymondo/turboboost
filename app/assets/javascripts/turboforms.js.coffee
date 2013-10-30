@Turboforms =
  insertError: true

turboforms = "form[data-turboform]"
errID = "#error_explanation"
errTemplate = (errors) ->
  "<ul><li>#{$.makeArray(JSON.parse(errors)).join('</li><li>')}</li></ul>"

enableForm = ($form) ->
  $form.find("[type='submit']").removeAttr('disabled')

disableForm = ($form) ->
  $form.find("[type='submit']").attr('disabled', 'disabled')

insertErrors = (e, errors) ->
  return if !Turboforms.insertError
  $form = $(e.target)
  $el = $form.find(errID)
  if !$el.length
    $form.prepend $el = $("<div id='#{errID.substr(1)}'></div>")
  $el.html errTemplate(errors)

$(document)
  .on "ajax:beforeSend", turboforms, (e, xhr, settings) ->
    xhr.setRequestHeader('X-Turboforms', 'enabled')
    disableForm $(e.target)
    if settings.type == "GET"
      Turbolinks.visit [@action, $(@).serialize()].join("?")
      return false

  .on "ajax:complete", turboforms, (e, resp) ->
    if resp.status in [200..209]
      $(e.target).trigger "turboform:success", resp.getResponseHeader('Notice')
      Turbolinks.visit(location) if location = resp.getResponseHeader('Location')
    if resp.status in [422, 500]
      enableForm $(e.target)
      $(e.target).trigger "turboform:error", resp.responseText

  .on "turboform:error", insertErrors
