## Turbolinks for your Rails forms

### Design Pattern

In order to bring AJAX control over your Rails app in a Turbolinks compatible way, you have to define some assumptions. The way Turboforms currently works is:

* For GET requests, visit the form's action with the serialized data appended to as a query string with Turbolinks.
* For other request types, hit the Rails controller. Then:
    - If the response has a `redirect_to` declaration, visit that route with Turbolinks.
    - If there is an exception error(s), do not visit anything with Turbolinks. The errors will be sent to the global document event `turboform:error`.
* Turboforms only works on forms that you define with `turboform: true` in your Rails form helper options or manually as a `data-turboform` attribute.
* When a Turboform has an AJAX request in process, do sensible things like disable the form's submit button.

These definitions are definitely open to discussion.

### Installation

``` ruby
gem "turbolinks"  
gem "jquery-rails"  
gem "turboforms", github: "waymondo/turboforms"
```

Put that in your `Gemfile` and `bundle install`. In your `application.js` put:

``` javascript
//= require jquery  
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

In your controller, the simplest example of handling a server response would look something like:

``` ruby
def create
  @post = Post.new(params[:post])
  @post.save! # <- trigger exception on invalid model
  redirect_to @post, notice: 'Post was successfully created.'
end
```

If the post is invalid, a `rescue_from` handler will pass off the errors to JavaScript through the `turboform:error` event.

You can also render the JSON error messages explicitly with the method `render_turboforms_error(record)`:

``` ruby
def create
  @post = Post.new(post_params)
  if @post.save
    redirect_to @post, notice: 'Post was successfully created.'
  else
    respond_to do |format|
      format.html { render 'new' }
      format.js { render_turboforms_error(@post) }
    end
  end
end
```

### JavaScript options and events

By default, Turboforms will render returned errors with the same URL structure used in the default Rails generators and prepend it to the form. The structure looks like this:

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

There is also a `turboform:success` event that is trigger and passed `flash[:notice]` if it is present:

``` coffeescript
$(document).on "turboform:success", (e, notice) ->
  console.log(notice) # -> "Post was successfully created."
```


