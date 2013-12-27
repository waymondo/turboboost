## Turboboost

Turboboost extends the power of Turbolinks into the forms of your Rails app and provides convenient success and error handlers. It aims to be a seemless and logical addition to any Turbolinks-rocking Rails 3.2+/4+ app. The main features are:

* Response redirection is handled by Turbolinks.

* Customizable success and error handling through registered JavaScript events, with optional error rendering built-in.

* Responses can also be rendered within the DOM using jQuery selectors.

<!-- The main features are: -->

<!-- * Integration into Turbolinks-managed browser history states. -->

<!-- * Faster loading upon successful form submissions with redirects, as only the body is swapped out. -->

<!-- * Customizable success and error handling through registered JavaScript events, with optional error rendering built-in. -->

<!-- As a bonus: since failed form submissions are caught and returned with JavaScript, you can cache your views harder since you don't have to re-render your form view with the model in an invalid state. -->

<!-- ### Design Pattern -->

<!-- In order to bring AJAX control over your Rails app's forms in a Turbolinks compatible way, you have to define some assumptions. The way Turboboost currently works is: -->

<!-- * For GET requests, visit the form's action with the serialized data appended to as a query string with Turbolinks. This will preserve navigable history states for things like search filter forms. -->
<!-- * For other request types, hit your Rails controllers then: -->
<!--     - If the response has a `redirect_to` declaration, do not reload. Instead, visit that route with Turbolinks. -->
<!--     - If there is an error, don't visit anything with Turbolinks. Instead, the errors will be sent through the global document event `turboboost:error`. Optionally, the errors can be prepended to the form as HTML. -->
<!-- * Turboboost only works on forms that you define with `turboboost: true` in your Rails form helper options or manually with a `data-turboboost` attribute. -->
<!-- * When a Turboboost has an AJAX request in process, do sensible things like disable that form's submit button. -->

<!-- These are definitely open to discussion. The goal here is to be Rails 3.2+ and Rails 4+ compatible.  -->

### Installation

``` ruby
gem "turboboost"
```

Put that in your `Gemfile` and `bundle install`. In your `application.js` require it after `jquery_ujs` and `turbolinks`:

``` javascript
//= require jquery_ujs  
//= require turbolinks  
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

### Usage

#### Redirection with Turbolinks

In its simplest server-side implementation, a basic Turboboost controller action with redirection might look like this:

``` ruby
def create
  post = Post.create!(params[:post]) <- trigger exception if model is invalid
  redirect_to post, notice: 'Post was successfully created.'
end
```

If the post is successfully created, the app will visit the `post_url` with Turbolinks if it was sent from a Turboboost. Otherwise, the redirect will happen like normal.

#### Error Handling and Flash Messages

If the post in our example above is invalid, no redirect will happen and a `rescue_from` handler will pass off the errors to JavaScript through the `turboboost:error` event:

``` coffeescript
$(document).on "turboboost:error", (e, errors) ->
  console.log(errors) # <- JSON array of errors messages
```

You can also trigger the JSON error messages explicitly with the method `render_turboboost_errors_for(record)` if you don't want to use the `rescue_from` handler:

``` ruby
def create
  @post = Post.new(post_params)
  if @post.save
    redirect_to @post, notice: 'Post was successfully created.'
  else
    respond_to do |format|
      format.html { render 'new' }
      format.js { render_turboboost_errors_for(@post) }
    end
  end
end
```

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

Currently Turboboost will handle invalid `ActiveRecord` and `ActiveModel` error messages as well as basic HTTP error messages.

There is also a `turboboost:success` event that is triggered and passed a hash of all current flash messages if they are present:

``` coffeescript
$(document).on "turboboost:success", (e, flash) ->
  console.log(flash) # -> {'notice': 'Post was successfully created.'}
```

You may also prevent redirecting on any Turboboost by adding the attribute `data-no-turboboost-redirect` to your form element if you just want to handle the response and returned flash messages manually:

#### Scoped response rendering

Turboboost also provides some extra rendering options for letting you render your form responses at specific locations in the DOM:

|Rails controller render option | jQuery function|
|-------------------------------|:---------------|
|`:within`                      |`html()`        |
|`:replace`                     |`replaceWith()` |
|`:prepend`                     |`prepend()`     |
|`:append`                      |`append()`      |

The value can be any jQuery selector. Example usage:

``` ruby
respond_to do |format|
  format.js { render partial: 'task', object: @task, prepend: "#todo-list" }
end
```

or:

``` ruby
respond_to do |format|
  format.js { render partial: 'task', object: @task, replace: "#todo-item#{@task.id}" }
end
```

### Todo

* More tests, obviously.

