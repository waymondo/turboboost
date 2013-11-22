## Turboforms

Turboforms plugs the power of Turbolinks into the form requests in your Rails app. It aims to be a seemless and logical addition to any Turbolinks-rocking Rails app. The main features are:

* Integration into Turbolinks-managed browser history states.

* Faster loading upon successful form submissions with redirects, as only the body is swapped out.

* Customizable success and error handling through registered JavaScript events, with optional error rendering built-in.

As a bonus: since failed form submissions are caught and returned with JavaScript, you can cache your views harder since you don't have to re-render your form view with the model in an invalid state.

### Design Pattern

In order to bring AJAX control over your Rails app's forms in a Turbolinks compatible way, you have to define some assumptions. The way Turboforms currently works is:

* For GET requests, visit the form's action with the serialized data appended to as a query string with Turbolinks. This will preserve navigable history states for things like search filter forms.
* For other request types, hit your Rails controllers then:
    - If the response has a `redirect_to` declaration, do not reload. Instead, visit that route with Turbolinks.
    - If there is an error, don't visit anything with Turbolinks. Instead, the errors will be sent through the global document event `turboform:error`. Optionally, the errors can be prepended to the form as HTML.
* Turboforms only works on forms that you define with `turboform: true` in your Rails form helper options or manually with a `data-turboform` attribute.
* When a Turboform has an AJAX request in process, do sensible things like disable that form's submit button.

These are definitely open to discussion. The goal here is to be Rails 3.2+ and Rails 4+ compatible. 

### Installation

``` ruby
gem "turboforms", github: "waymondo/turboforms"
```

Put that in your `Gemfile` and `bundle install`. In your `application.js` require it after `jquery_ujs` and `turbolinks`:

``` javascript
//= require jquery_ujs  
//= require turbolinks  
//= require turboforms
```

### Example Usage

In your view:

```
= form_for @post, turboform: true do |f| ...
```

or:

```
<form data-turboform> ...
```

In its simplest server-side implementation, a controller action would look like this:

``` ruby
def create
  post = Post.create!(params[:post]) <- trigger exception if model is invalid
  redirect_to post, notice: 'Post was successfully created.'
end
```

If the post is invalid, a `rescue_from` handler will pass off the errors to JavaScript through the `turboform:error` event. If the post is successfully created, the app will visit the `post_url` with Turbolinks if it was sent from a Turboform. Otherwise, the redirect will happen like normal.

You can also render the JSON error messages explicitly with the method `render_turboform_errors_for(record)`:

``` ruby
def create
  @post = Post.new(post_params)
  if @post.save
    redirect_to @post, notice: 'Post was successfully created.'
  else
    respond_to do |format|
      format.html { render 'new' }
      format.js { render_turboform_errors_for(@post) }
    end
  end
end
```

Currently, Turboforms will handle invalid `ActiveModel` error messages as well as general `Exception` messages.

### JavaScript options and events

By default, Turboforms will render returned errors with the same HTML structure used in the default Rails generators and prepend it to the form. The structure looks like this:

``` html
<div id="error_explanation">
  <ul>
    {{#errors}}
      <li>{{this}}</li>
    {{/errors}}
  </ul>
</div>
```

Or this can be disabled and you can roll your own error handler:

``` coffeescript
Turboforms.insertErrors = false

$(document).on "turboform:error", (e, errors) ->
  console.log(errors) # <- JSON array of errors messages
```

There is also a `turboform:success` event that is trigger and passed a hash of the flash messages if they are present. You may also prevent redirecting on any Turboform by adding the attribute `data-no-turboform-redirect` to your form element if you just want to handle the response and returned flash messages manually:

``` coffeescript
$(document).on "turboform:success", (e, flash) ->
  console.log(flash) # -> {'notice': 'Post was successfully created.'}
```

## Todo

* More tests, obviously.
* Extended error/exception white-listing handling (currently handles HTTP and ActiveRecord/ActiveModel validation errors).
* controller action `render_turboform_success` for rendering views/partials within CSS selectors.

