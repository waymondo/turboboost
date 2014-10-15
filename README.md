## Turboboost

Turboboost extends the power of Turbolinks into the forms of your Rails app and provides additional convenient AJAX handlers for forms and links. It aims to be a seemless and logical addition to any Turbolinks-rocking Rails 3.2+/4+ app. Currently it depends on jQuery. The main features are:

* Form response redirection is handled by Turbolinks.
* Customizable success and error handling through registered JavaScript, with support for Rails' Flash and optional error rendering built-in.
* Responses can also be rendered within a scoped DOM target using jQuery selectors.

### Installation

In your `Gemfile`:

``` ruby
gem "turboboost"
```

In your `application.js`:

``` javascript
//= require turboboost
```

Then in your view files, add `turboboost: true` to your form helpers:

```
= form_for :resource, turboboost: true do |f| ...
```

or add the data attribute manually:

```
<form data-turboboost> ...
```

### Redirection with Turbolinks

In its simplest server-side implementation, a basic Turboboost controller action with redirection might look like this:

``` ruby
def create
  post = Post.create!(params[:post]) # <- trigger exception if model is invalid
  redirect_to post, notice: 'Post was successfully created.'
end
```

If the post is successfully created through a Turboboost-ed form, the app will visit the post's URL with Turbolinks. Otherwise, the redirect will happen like normal.

If a Turboboost form makes a GET request, it will serialize the form's data and then visit its action URL with the data serialized as parameters with Turbolinks.

### Error handling

If the post in our example above is invalid, no redirect will happen and a `rescue_from` handler will pass the errors to JavaScript through the `turboboost:error` event:

``` coffeescript
$(document).on "turboboost:error", (e, errors) ->
  console.log(errors) # <- JSON array of errors messages
```

You can also trigger the JSON error messages explicitly with the method `render_turboboost_errors_for(record)` if you don't want to use the default `rescue_from` handler:

``` ruby
def create
  @post = Post.new(post_params)
  if @post.save
    flash[:notice] = 'Post was successfully created.'
    redirect_to @post
  else
    respond_to do |format|
      format.html { render :new }
      format.js { render_turboboost_errors_for(@post) }
    end
  end
end
```

#### Automatic error message insertion

Optionally, Turboboost can render returned errors with the same HTML structure used in the default Rails generators and prepend it to the form. The HTML structure looks like this:

``` html
<div id="error_explanation">
  <ul>
    {{#errors}}
      <li>{{this}}</li>
    {{/errors}}
  </ul>
</div>
```

To turn it on:

``` coffeescript
Turboboost.insertErrors = true
```

By default, this will prepend the error message to the form. Other values can be "append", "beforeSubmit", "afterSubmit", or any jQuery selector within the form:

``` coffeescript
Turboboost.insertErrors = '.error-wrap'
```

#### Error internationalization

Currently Turboboost will handle invalid `ActiveRecord` and `ActiveModel` error messages as well as basic HTTP error messages. For ActiveRecord validations, it will use [Rails' I18n lookup](http://guides.rubyonrails.org/i18n.html#translations-for-active-record-models) to retrieve the message wording. For other raised exceptions, you can customize the basic wording using the I18n namespace format `turboboost.errors.#{error.class.name}`:

``` yaml
en:
  turboboost:
    errors:
      "ActiveRecord::RecordNotFound": "Shoot, didn't find anything."
```

### Ajax flash message handling

There is also a `turboboost:success` event that is triggered and passed a hash of all current flash messages if they are present:

``` coffeescript
$(document).on "turboboost:success", (e, flash) ->
  console.log(flash) # -> {'notice': 'Post was successfully created.'}
```

### Scoped response rendering

Turboboost also provides some options for rendering AJAX responses at specific locations in the DOM:

|Rails controller render option | jQuery function|
|-------------------------------|:---------------|
|`:within`                      |`html()`        |
|`:replace`                     |`replaceWith()` |
|`:prepend`                     |`prepend()`     |
|`:append`                      |`append()`      |

The value can be any jQuery selector. Example usage:

``` ruby
respond_to do |format|
  format.html
  format.js { render partial: 'task', object: @task, prepend: "#todo-list" }
end
```

