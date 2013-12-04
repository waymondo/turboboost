@Turboboost =
  insertErrors: false
  defaultError: "Sorry, there was an error."

turboboostable = "[data-turboboost]"
errID = "#error_explanation"
errTemplate = (errors) ->
  "<ul><li>#{$.makeArray(errors).join('</li><li>')}</li></ul>"

enableForm = ($form) ->
  $form.find("[type='submit']").removeAttr('disabled')

disableForm = ($form) ->
  $form.find("[type='submit']").attr('disabled', 'disabled')

turboboostFormError = (e, errors) ->
  return if !Turboboost.insertErrors
  errors = [Turboboost.defaultError] if !errors.length
  $form = $(e.target)
  $el = $form.find(errID)
  if !$el.length
    $form.prepend $el = $("<div id='#{errID.substr(1)}'></div>")
  $el.html errTemplate(errors)

turboboostComplete = (e, resp) ->
  $el = $(@)
  isForm = @nodeName is "FORM"

  if resp.status in [200..299]
    $el.trigger "turboboost:success", tryJSONParse resp.getResponseHeader('X-Flash')
    if (location = resp.getResponseHeader('Location')) and !$el.attr('data-no-turboboost-redirect')
      Turbolinks.visit(location)
    else
      enableForm $el if isForm
      maybeInsertSuccessResponseBody(resp)

  if resp.status in [400..599]
    enableForm $el if isForm
    $el.trigger "turboboost:error", tryJSONParse resp.responseText

turboboostFormBeforeSend = (e, xhr, settings) ->
  disableForm $(@)
  if settings.type == "GET"
    Turbolinks.visit [@action, $(@).serialize()].join("?")
    return false

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
  .on("ajax:beforeSend", turboboostable, (e, xhr, settings) ->
    xhr.setRequestHeader('X-Turboboost', '1'))
  .on("ajax:beforeSend", "form#{turboboostable}", turboboostFormBeforeSend)
  .on("ajax:complete", turboboostable, turboboostComplete)
  .on("turboboost:error", "form#{turboboostable}", turboboostFormError)
