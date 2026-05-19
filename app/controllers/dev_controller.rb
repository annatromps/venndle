class DevController < ApplicationController
  before_action { raise ActionController::RoutingError, "Not found" unless Rails.env.development? }

  def reset
    if user_signed_in?
      user = current_user
      GameSession.where(user: user).destroy_all
      Attempt.where(user: user).destroy_all
      redirect_to root_path, notice: "Reset: all game sessions and attempts cleared for #{user.username}"
    else
      redirect_to root_path, alert: "Sign in first"
    end
  end
end
