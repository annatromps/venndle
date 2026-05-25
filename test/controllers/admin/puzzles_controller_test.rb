require "test_helper"

class Admin::PuzzlesControllerTest < ActionDispatch::IntegrationTest
  # ── unschedule ───────────────────────────────────────────────────────────────

  test "unscheduling an admin-created puzzle restores it to the admin library" do
    sign_in users(:admin_user)
    puzzle = puzzles(:future_daily)

    patch unschedule_admin_puzzle_path(puzzle)

    puzzle.reload
    assert_equal "admin", puzzle.puzzle_type
    assert_nil puzzle.scheduled_date
    assert_equal false, puzzle.published
    assert_redirected_to admin_puzzles_path
  end

  test "unscheduling a community puzzle returns it to the community list" do
    sign_in users(:admin_user)
    puzzle = puzzles(:scheduled_community_puzzle)

    patch unschedule_admin_puzzle_path(puzzle)

    puzzle.reload
    assert_equal "user", puzzle.puzzle_type
    assert_nil puzzle.scheduled_date
    assert_redirected_to puzzles_path
  end

  test "non-admin cannot unschedule a puzzle" do
    sign_in users(:alice)
    puzzle = puzzles(:future_daily)

    patch unschedule_admin_puzzle_path(puzzle)

    assert_redirected_to root_path
  end
end
