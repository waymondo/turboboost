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
require 'turboboost'

ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'

class TestApp < Rails::Application; end
Rails.application = TestApp
Rails.configuration.secret_key_base = 'abc123'

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

posts_table = %{CREATE TABLE posts (id INTEGER PRIMARY KEY, title VARCHAR(5), user_id INTEGER);}
ActiveRecord::Base.connection.execute(posts_table)

class Post < ActiveRecord::Base
  attr_accessor :title, :user_id

  validates :title, length: { minimum: 5, message: 'is too short.' }
  validates :user_id, presence: true
end

users_table = %{CREATE TABLE users (id INTEGER PRIMARY KEY, name VARCHAR(5), email VARCHAR(255));}
ActiveRecord::Base.connection.execute(users_table)

class User < ActiveRecord::Base
  attr_accessor :name, :email

  validates :name, presence: true
  validates :email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, allow_blank: false }
end

items_table = %{CREATE TABLE items (id INTEGER PRIMARY KEY, name VARCHAR(5));}
ActiveRecord::Base.connection.execute(items_table)

class Item < ActiveRecord::Base
  attr_accessor :name

  validates :name, presence: true
end
