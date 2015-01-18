class PostsController < ApplicationController
  respond_to :html
  respond_to :js, only: [:create, :update, :destroy]

  def create
    Post.create!(post_params)
    redirect_to posts_url, notice: 'Post was successfully created.'
  end

  def update
    post = Post.find(params[:id])
    post.update_attributes!(post_params)
    redirect_to post_url(post), notice: 'Post was successfully updated.'
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
