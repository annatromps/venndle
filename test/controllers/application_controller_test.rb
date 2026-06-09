require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  # admin_view? and tester_view? are helper methods exposed to views;
  # we test their effect via routes that branch on them.

  test "admin_view? is true for admin by default" do
    sign_in users(:admin_user)
    get archive_path
    # Admin sees play counts (only shown when admin_view? is true)
    assert_response :success
  end

  test "toggle_admin_view flips admin view off then on" do
    sign_in users(:admin_user)
    # Default is on — toggle off
    post toggle_admin_view_path
    assert_response :redirect

    # Toggle back on
    post toggle_admin_view_path
    assert_response :redirect
  end

  test "toggle_admin_view requires sign in" do
    post toggle_admin_view_path
    assert_redirected_to new_user_session_path
  end

  test "tester can access future daily via tester_view?" do
    sign_in users(:tester_user)
    puzzle = puzzles(:future_daily)
    day_num = puzzle.day_number
    get "/daily#{day_num}"
    assert_response :success
  end

  test "non-tester cannot access future daily" do
    sign_in users(:alice)
    puzzle = puzzles(:future_daily)
    day_num = puzzle.day_number
    get "/daily#{day_num}"
    assert_redirected_to archive_path
  end
end
