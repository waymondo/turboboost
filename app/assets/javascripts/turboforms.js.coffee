@Turboforms =
  insertErrors: false
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

maybeInsertSuccessResponseBody = (resp) ->
  if (scope = resp.getResponseHeader('X-Within'))
    $(scope).html(resp.responseText)
  else if (scope = resp.getResponseHeader('X-Replace'))
    $(scope).replaceWith(resp.responseText)
  else if (scope = resp.getResponseHeader('X-Append'))
    $(scope).append(resp.responseText)
  else if (scope = resp.getResponseHeader('X-Prepend'))
    $(scope).prepend(resp.responseText)

$(document)
  .on "ajax:beforeSend", turboforms, (e, xhr, settings) ->
    xhr.setRequestHeader('X-Turboforms', '1')
    disableForm $(e.target)
    if settings.type == "GET"
      Turbolinks.visit [@action, $(@).serialize()].join("?")
      return false

  .on "ajax:complete", turboforms, (e, resp) ->
    $form = $(e.target)

    if resp.status in [200..299]
      $form.trigger "turboform:success", tryJSONParse resp.getResponseHeader('X-Flash')
      if (location = resp.getResponseHeader('Location')) and !$form.attr('data-no-turboform-redirect')
        Turbolinks.visit(location)
      else
        enableForm $form
        maybeInsertSuccessResponseBody(resp)

    if resp.status in [400..599]
      enableForm $form
      $form.trigger "turboform:error", tryJSONParse resp.responseText

  .on "turboform:error", insertErrors
