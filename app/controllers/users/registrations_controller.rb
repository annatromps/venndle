class Users::RegistrationsController < Devise::RegistrationsController
  def create
    super do |resource|
      session[:just_signed_up] = true if resource.persisted?
    end
  end
end
