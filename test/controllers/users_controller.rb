class UsersController < ApplicationController
  def create
    user = User.new(user_params)
    if user.save
      flash[:notice] = 'User was successfully created.'
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
