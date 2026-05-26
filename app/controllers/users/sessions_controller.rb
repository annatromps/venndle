class Users::SessionsController < Devise::SessionsController
  def create
    request.params[:user] ||= {}
    request.params[:user][:remember_me] = "1"
    super
  end
end
