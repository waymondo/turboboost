require 'test_helper'

class Post
  extend ActiveModel::Naming

  include ActiveModel::Conversion
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :title

  validates! :title, length: { minimum: 1, message: "is too short." }

  def self.create!(attributes)
    post = self.new(attributes)
    post.save
  end

  def save
    valid?
  end

  def update_attributes
    valid?
  end

end

class PostsController < ApplicationController

  respond_to :html
  respond_to :js, only: [:create, :update, :destroy]

  def index; end
  def show; end
  def new; end
  def edit; end

  def create
    post = Post.create!(params[:post])
    redirect_to posts_url, notice: "Post was successfully created."
  end

  def update
    post = Post.find(params[:id])
    if post.update_attributes(params[:post])
      redirect_to post_url(post)
    else
      respond_to do |format|
        format.html { redirect_to posts_url }
        format.js { render_turboforms_error_for(post) }
      end
    end
  end

  def destroy
    post = Post.find(params[:id])
    post.destroy!
    redirect_to posts_url
  end

end

class PostsControllerTest < ActionController::TestCase

  tests PostsController

  setup do
    @request.headers["X-Turboforms"] = "1"
  end

  test "On a successful turboform request, return an empty response with headers containing the redirect location and flash message" do
    xhr :post, :create, post: { title: "Foo" }

    assert @response.body.strip.blank?
    assert_equal flash[:notice], 'Post was successfully created.'
    assert_equal @response.headers["Location"], posts_url
    assert_equal JSON.parse(@response.headers["X-Flash"])["notice"], 'Post was successfully created.'
  end

  test "On an unsuccessful turboform request, catch and return the error message(s) as an array" do
    xhr :post, :create, post: { title: "" }

    assert_equal @response.status, 500
    assert_equal @response.body.strip, ["Title is too short."].to_json
  end

  test "On an unsuccessful turboform request, explicitly render the error message(s)" do
    skip
  end

end
