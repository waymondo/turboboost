require 'test_helper'

class PostsController < ApplicationController

  respond_to :html
  respond_to :js, only: [:create, :update, :destroy]

  def create
    post = Post.create!(post_params)
    redirect_to posts_url, notice: "Post was successfully created."
  end

  def update
    post = Post.find(params[:id])
    post.update_attributes!(post_params)
    redirect_to post_url(post), notice: "Post was successfully updated."
  end

  def destroy
    post = Post.find(params[:id])
    post.destroy!
    redirect_to posts_url
  end

private

  def post_params
    params.require(:post).permit(:title, :user_id)
  end

end

class UsersController < ApplicationController

  def create
    user = User.new(user_params)
    if user.save
      flash[:notice] = "User was successfully created."
      redirect_to user_url(user)
    else
      respond_to do |format|
        format.html { render :new }
        format.js { render_turboboost_errors_for(user) }
      end
    end
  end

  def update
    user = User.find(params[:id])
    if user.update_attributes(user_params)
      redirect_to user_url(user)
    else
      respond_to do |format|
        format.html { redirect_to users_url }
        format.js { render_turboboost_errors_for(user) }
      end
    end
  end

private

  def user_params
    params.require(:user).permit(:name, :email)
  end

end

class PostsControllerTest < ActionController::TestCase

  tests PostsController

  setup do
    @request.headers["X-Turboboost"] = "1"
  end

  test "On a successful turboboost request, return an empty response with headers containing the redirect location and flash message" do
    xhr :post, :create, post: { title: "Foobar", user_id: "1" }

    assert @response.body.strip.blank?
    assert_equal flash[:notice], 'Post was successfully created.'
    assert_equal @response.headers["Location"], posts_url
    assert_equal JSON.parse(@response.headers["X-Flash"])["notice"], 'Post was successfully created.'
  end

  test "On an unsuccessful turboboost request, catch and return the error message(s) as an array" do
    xhr :post, :create, post: { title: "Title", user_id: nil }

    assert_equal @response.status, 422
    assert_equal @response.body.strip, ["User can't be blank"].to_json

    xhr :post, :create, post: { title: "Tit", user_id: nil }

    assert_equal @response.status, 422
    assert_equal @response.body.strip, ["Title is too short.", "User can't be blank"].to_json
  end

end


class UsersControllerTest < ActionController::TestCase

  tests UsersController

  setup do
    @request.headers["X-Turboboost"] = "1"
  end

  test "On a successful turboboost request, return an empty response with headers containing the redirect location and flash message" do
    xhr :post, :create, user: { name: "Mike", email: "mike@mike.com" }

    assert @response.body.strip.blank?
    assert_equal flash[:notice], 'User was successfully created.'
    assert_equal @response.headers["Location"], user_url(1)
    assert_equal JSON.parse(@response.headers["X-Flash"])["notice"], 'User was successfully created.'
  end

  test "On an unsuccessful turboboost request, explicitly render the error message(s)" do
    xhr :post, :create, user: { name: "Mike", email: "mike at mike.com" }

    assert_equal @response.status, 422
    assert_equal @response.body.strip, ["Email is invalid"].to_json
  end

end
