require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "signup with email creates user with that email" do
    assert_difference "User.count", 1 do
      post user_registration_path, params: {
        user: { username: "newuser1", email: "newuser1@example.com", password: "password123", password_confirmation: "password123" }
      }
    end
    user = User.find_by(username: "newuser1")
    assert_not_nil user
    assert_equal "newuser1@example.com", user.email
    assert_not user.email_is_placeholder?
  end

  test "signup without email generates placeholder email" do
    assert_difference "User.count", 1 do
      post user_registration_path, params: {
        user: { username: "newuser2", email: "", password: "password123", password_confirmation: "password123" }
      }
    end
    user = User.find_by(username: "newuser2")
    assert_not_nil user
    assert user.email_is_placeholder?
    assert user.email.start_with?("newuser2-")
    assert user.email.end_with?(User::PLACEHOLDER_EMAIL_DOMAIN)
  end

  test "placeholder email is unique per signup" do
    post user_registration_path, params: {
      user: { username: "newuser3a", email: "", password: "password123", password_confirmation: "password123" }
    }
    post user_registration_path, params: {
      user: { username: "newuser3b", email: "", password: "password123", password_confirmation: "password123" }
    }
    emails = User.where("email LIKE ?", "%#{User::PLACEHOLDER_EMAIL_DOMAIN}").pluck(:email)
    assert_equal emails.uniq.length, emails.length
  end

  test "signup without username fails" do
    assert_no_difference "User.count" do
      post user_registration_path, params: {
        user: { username: "", email: "", password: "password123", password_confirmation: "password123" }
      }
    end
  end
end
