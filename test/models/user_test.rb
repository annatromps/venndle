require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid with email username and password" do
    u = User.new(email: "new@example.com", username: "newuser", password: "password123")
    assert u.valid?
  end

  test "invalid without username" do
    u = User.new(email: "x@example.com", password: "password123")
    assert_not u.valid?
    assert u.errors[:username].any?
  end

  test "invalid with duplicate username" do
    u = User.new(email: "other@example.com", username: "alice", password: "password123")
    assert_not u.valid?
    assert u.errors[:username].any?
  end

  test "invalid with duplicate email" do
    u = User.new(email: "alice@example.com", username: "alice2", password: "password123")
    assert_not u.valid?
    assert u.errors[:email].any?
  end

  test "admin? returns true for admin user" do
    assert users(:admin_user).admin?
  end

  test "admin? returns false for regular user" do
    assert_not users(:alice).admin?
  end

  test "has many game sessions" do
    assert_respond_to users(:alice), :game_sessions
    assert_includes users(:alice).game_sessions, game_sessions(:alice_past_completed)
  end

  test "has many puzzles" do
    assert_respond_to users(:alice), :puzzles
  end

  test "has many favourite puzzles through favourites" do
    assert_respond_to users(:alice), :favourite_puzzles
  end
end
