class Users::RegistrationsController < Devise::RegistrationsController
  before_action :fill_placeholder_email, only: [:create]

  def create
    super do |resource|
      session[:just_signed_up] = true if resource.persisted?
    end
  end

  private

  def fill_placeholder_email
    return if params.dig(:user, :email).present?
    username = params.dig(:user, :username).to_s.strip.downcase.gsub(/[^a-z0-9_]/, "")
    base = username.presence || "user"
    params[:user][:email] = "#{base}-#{SecureRandom.hex(4)}#{User::PLACEHOLDER_EMAIL_DOMAIN}"
  end
end
