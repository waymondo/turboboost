(function() {
  var disableForm, enableForm, errID, errTemplate, formProcessingClass, insertErrorContainer, maybeInsertSuccessResponseBody, maybeReenableForms, renderFunctionForOption, restrictResponseToBody, tryJSONParse, turboboostBeforeSend, turboboostComplete, turboboostFormError, turboboostable;

  this.Turboboost = {
    insertErrors: false,
    handleFormDisabling: true,
    defaultError: "Sorry, there was an error."
  };

  turboboostable = "[data-turboboost]";

  errID = "#error_explanation";

  errTemplate = function(errors) {
    return "<ul><li>" + ($.makeArray(errors).join('</li><li>')) + "</li></ul>";
  };

  formProcessingClass = 'turboboost-form-processing';

  enableForm = function($form) {
    $form.removeClass(formProcessingClass);
    return $form.find("[type='submit']").removeAttr('disabled').data('turboboostDisabled', false);
  };

  disableForm = function($form) {
    $form.addClass(formProcessingClass);
    return $form.find("[type='submit']").attr('disabled', 'disabled').data('turboboostDisabled', true);
  };

  tryJSONParse = function(str) {
    var e;
    try {
      return JSON.parse(str);
    } catch (error) {
      e = error;
      return null;
    }
  };

  insertErrorContainer = function($form) {
    var $el;
    $el = $("<div id='" + (errID.substr(1)) + "'></div>");
    switch (Turboboost.insertErrors) {
      case "append":
        $form.append($el);
        break;
      case "beforeSubmit":
        $form.find("[type='submit']").before($el);
        break;
      case "afterSubmit":
        $form.find("[type='submit']").after($el);
        break;
      case true:
        $form.prepend($el);
        break;
      default:
        if (Turboboost.insertErrors.match(/^\W+/)) {
          $form.find(Turboboost.insertErrors).html($el);
        } else {
          $form.prepend($el);
        }
    }
    return $el;
  };

  turboboostFormError = function(e, errors) {
    var $el, $form;
    if (!Turboboost.insertErrors) {
      return;
    }
    errors = tryJSONParse(errors);
    if (!errors.length) {
      errors = [Turboboost.defaultError];
    }
    $form = $(e.target);
    $el = $form.find(errID);
    if (!$el.length) {
      $el = insertErrorContainer($form);
    }
    return $el.html(errTemplate(errors));
  };

  turboboostComplete = function(e, resp) {
    var $el, $inserted, isForm, location, status;
    $el = $(this);
    isForm = this.nodeName === "FORM";
    status = parseInt(resp.status);
    if ((200 <= status && status < 300)) {
      $el.trigger("turboboost:success", tryJSONParse(resp.getResponseHeader('X-Flash')));
      if (Turboboost.insertErrors && isForm) {
        $el.find(errID).remove();
      }
      if ((location = resp.getResponseHeader('Location')) && !$el.attr('data-no-turboboost-redirect')) {
        e.preventDefault();
        e.stopPropagation();
        Turbolinks.visit(location);
        return;
      } else {
        if (isForm && Turboboost.handleFormDisabling) {
          enableForm($el);
        }
        $inserted = maybeInsertSuccessResponseBody(resp);
      }
    } else if ((400 <= status && status < 600)) {
      if (isForm && Turboboost.handleFormDisabling) {
        enableForm($el);
      }
      $el.trigger("turboboost:error", resp.responseText);
    }
    if ($.contains(document.documentElement, $el[0])) {
      return $el.trigger("turboboost:complete");
    } else if ($inserted) {
      return $inserted.trigger("turboboost:complete");
    }
  };

  turboboostBeforeSend = function(e, xhr, settings) {
    var $el, isForm;
    xhr.setRequestHeader('X-Turboboost', '1');
    isForm = this.nodeName === "FORM";
    if (!isForm) {
      return e.stopPropagation();
    }
    $el = $(this);
    if (isForm && Turboboost.handleFormDisabling) {
      disableForm($el);
    }
    if (settings.type === "GET" && !$el.attr('data-no-turboboost-redirect')) {
      Turbolinks.visit([this.action, $el.serialize()].join("?"));
      return false;
    }
  };

  renderFunctionForOption = function(option) {
    switch (option) {
      case 'within':
        return 'html';
      case 'replace':
        return 'replaceWith';
      default:
        return option;
    }
  };

  restrictResponseToBody = function(html) {
    var doc;
    if (/<(html|body)/i.test(html)) {
      doc = document.documentElement.cloneNode();
      doc.innerHTML = html;
      return doc.querySelector('body').innerHTML;
    } else {
      return html;
    }
  };

  maybeInsertSuccessResponseBody = function(resp) {
    var header, html, renderFunction, renderOption;
    if (!(header = tryJSONParse(resp.getResponseHeader('X-Turboboost-Render')))) {
      return;
    }
    html = restrictResponseToBody(resp.responseText);
    renderOption = Object.keys(header)[0];
    renderFunction = renderFunctionForOption(renderOption);
    return $(header[renderOption])[renderFunction](html);
  };

  maybeReenableForms = function() {
    if (!Turboboost.handleFormDisabling) {
      return;
    }
    return $("form" + turboboostable + " [type='submit']").each(function() {
      if ($(this).data('turboboostDisabled')) {
        return enableForm($(this).closest('form'));
      }
    });
  };

  $(document)
      .on("ajax:beforeSend", turboboostable, turboboostBeforeSend)
      .on("ajax:complete", turboboostable, turboboostComplete)
      .on("turboboost:error", "form" + turboboostable, turboboostFormError)
      .on("page:restore", maybeReenableForms);

}).call(this);