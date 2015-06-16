require 'rubygems'
require 'bundler'
Bundler.setup

ENV['RAILS_ENV'] = 'test'

require 'rails'
require 'active_record'
require 'action_controller'
require 'action_controller'
require 'action_controller/railtie'
require 'rails/test_help'
require 'awesome_print'
require 'responders' if Rails.version >= '4.2'
require 'strong_parameters' if Rails.version < '4.0'
require 'turboboost'

I18n.enforce_available_locales = true
I18n.load_path << File.expand_path('../locales/en.yml', __FILE__)
I18n.reload!

ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'

class TestApp < Rails::Application; end
Rails.application = TestApp
Rails.configuration.secret_key_base = 'abc123'

require 'support/models'

Turboboost::Routes = ActionDispatch::Routing::RouteSet.new
Turboboost::Routes.draw do
  resources 'posts'
  resources 'users'
  resources 'items'
end

class ApplicationController < ActionController::Base
  include Turboboost::Routes.url_helpers
  self.view_paths = File.join(File.dirname(__FILE__), 'views')
end

class ActiveSupport::TestCase
  setup do
    @routes = Turboboost::Routes
  end
end

class ActionView::TestCase
  include Turboboost::Routes.url_helpers
  include Turboboost::FormHelper
  def default_url_options
    {}
  end

  setup do
    @controller = ApplicationController
  end
end
