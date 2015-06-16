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
