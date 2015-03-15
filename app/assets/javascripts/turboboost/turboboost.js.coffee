@Turboboost =
  insertErrors: false
  handleFormDisabling: true
  defaultError: "Sorry, there was an error."

turboboostable = "[data-turboboost]"
errID = "#error_explanation"
errTemplate = (errors) ->
  "<ul><li>#{$.makeArray(errors).join('</li><li>')}</li></ul>"

enableForm = ($form) ->
  $form.find("[type='submit']").removeAttr('disabled').data('turboboostDisabled', false)

disableForm = ($form) ->
  $form.find("[type='submit']").attr('disabled', 'disabled').data('turboboostDisabled', true)

tryJSONParse = (str) ->
  try
    JSON.parse str
  catch e
    null

turboboostFormError = (e, errors) ->
  return if !Turboboost.insertErrors
  errors = tryJSONParse errors
  errors = [Turboboost.defaultError] if !errors.length
  $form = $(e.target)
  $el = $form.find(errID)
  if !$el.length
    $el = $("<div id='#{errID.substr(1)}'></div>")
    switch Turboboost.insertErrors
      when "append" then $form.append($el)
      when "beforeSubmit" then $form.find("[type='submit']").before($el)
      when "afterSubmit" then $form.find("[type='submit']").after($el)
      when true then $form.prepend($el)
      else
        if Turboboost.insertErrors.match(/^\W+/)
          $form.find(Turboboost.insertErrors).html($el)
        else
          $form.prepend($el)
  $el.html errTemplate(errors)

turboboostComplete = (e, resp) ->
  $el = $(@)
  isForm = @nodeName is "FORM"

  if resp.status in [200..299]
    $el.trigger "turboboost:success", tryJSONParse resp.getResponseHeader('X-Flash')
    $el.find(errID).remove() if Turboboost.insertErrors and isForm
    if (location = resp.getResponseHeader('Location')) and !$el.attr('data-no-turboboost-redirect')
      Turbolinks.visit(location)
    else
      enableForm $el if isForm and Turboboost.handleFormDisabling
      maybeInsertSuccessResponseBody(resp)

  if resp.status in [400..599]
    enableForm $el if isForm and Turboboost.handleFormDisabling
    $el.trigger "turboboost:error", resp.responseText

  $el.trigger "turboboost:complete"

turboboostBeforeSend = (e, xhr, settings) ->
  xhr.setRequestHeader('X-Turboboost', '1')
  isForm = @nodeName is "FORM"
  return e.stopPropagation() unless isForm
  $el = $(@)
  disableForm $el if Turboboost.handleFormDisabling
  if settings.type is "GET" and !$el.attr('data-no-turboboost-redirect')
    Turbolinks.visit [@action, $el.serialize()].join("?")
    return false

maybeInsertSuccessResponseBody = (resp) ->
  if (scope = resp.getResponseHeader('X-Within'))
    $(scope).html(resp.responseText)
  else if (scope = resp.getResponseHeader('X-Replace'))
    $(scope).replaceWith(resp.responseText)
  else if (scope = resp.getResponseHeader('X-Append'))
    $(scope).append(resp.responseText)
  else if (scope = resp.getResponseHeader('X-Prepend'))
    $(scope).prepend(resp.responseText)
  else if (scope = resp.getResponseHeader('X-Before'))
    $(scope).before(resp.responseText)
  else if (scope = resp.getResponseHeader('X-After'))
    $(scope).after(resp.responseText)

maybeReenableForms = ->
  return unless Turboboost.handleFormDisabling
  $("form#{turboboostable} input[type='submit']").each ->
    enableForm $(@).closest('form') if $(@).data('turboboostDisabled')

$(document)
  .on("ajax:beforeSend", turboboostable, turboboostBeforeSend)
  .on("ajax:complete", turboboostable, turboboostComplete)
  .on("turboboost:error", "form#{turboboostable}", turboboostFormError)
  .on("page:restore", maybeReenableForms)
