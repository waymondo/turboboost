require 'rubygems'
require 'bundler'
Bundler.setup

ENV["RAILS_ENV"] = "test"

require 'rails'
require "active_record"
require "action_controller"
require "action_controller"
require "action_controller/railtie"

require 'rails/test_help'
require 'awesome_print'

require 'turboboost'

class TestApp < Rails::Application; end
Rails.application = TestApp
Rails.configuration.secret_key_base = "abc123"

Turboboost::Routes = ActionDispatch::Routing::RouteSet.new
Turboboost::Routes.draw do
  resources 'posts'
end

class ApplicationController < ActionController::Base
  include Turboboost::Routes.url_helpers
end

class ActiveSupport::TestCase
  setup do
    @routes = Turboboost::Routes
  end
end
