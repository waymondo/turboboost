@Turboforms =
  insertErrors: true
  defaultError: "Sorry, there was an error."

turboforms = "form[data-turboform]"
errID = "#error_explanation"
errTemplate = (errors) ->
  "<ul><li>#{$.makeArray(errors).join('</li><li>')}</li></ul>"

enableForm = ($form) ->
  $form.find("[type='submit']").removeAttr('disabled')

disableForm = ($form) ->
  $form.find("[type='submit']").attr('disabled', 'disabled')

insertErrors = (e, errors) ->
  return if !Turboforms.insertErrors
  errors = [Turboforms.defaultError] if !errors.length
  $form = $(e.target)
  $el = $form.find(errID)
  if !$el.length
    $form.prepend $el = $("<div id='#{errID.substr(1)}'></div>")
  $el.html errTemplate(errors)

tryJSONParse = (str) ->
  try
    JSON.parse str
  catch e
    null

$(document)
  .on "ajax:beforeSend", turboforms, (e, xhr, settings) ->
    xhr.setRequestHeader('X-Turboforms', 'enabled')
    disableForm $(e.target)
    if settings.type == "GET"
      Turbolinks.visit [@action, $(@).serialize()].join("?")
      return false

  .on "ajax:complete", turboforms, (e, resp) ->
    $form = $(e.target)

    if resp.status in [200..209]
      $form.trigger "turboform:success", tryJSONParse resp.getResponseHeader('X-Flash')
      if (location = resp.getResponseHeader('Location')) and !$form.attr('data-no-turboform-redirect')
        Turbolinks.visit(location)
      else
        enableForm $form

    if resp.status in [422, 500]
      enableForm $form
      $form.trigger "turboform:error", tryJSONParse resp.responseText

  .on "turboform:error", insertErrors
