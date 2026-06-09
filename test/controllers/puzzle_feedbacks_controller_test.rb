require "test_helper"

class PuzzleFeedbacksControllerTest < ActionDispatch::IntegrationTest
  test "guest cannot submit feedback" do
    post puzzle_feedback_path(puzzles(:today_daily)), params: { body: "Great puzzle" }
    assert_redirected_to new_user_session_path
  end

  test "tester can submit feedback" do
    sign_in users(:tester_user)
    puzzle = puzzles(:today_daily)
    post puzzle_feedback_path(puzzle), params: { body: "Loved it" }
    assert_redirected_to :back
    fb = PuzzleFeedback.find_by(puzzle: puzzle, user: users(:tester_user))
    assert_not_nil fb
    assert_equal "Loved it", fb.body
  end

  test "tester can submit missing_answers alongside body" do
    sign_in users(:tester_user)
    puzzle = puzzles(:today_daily)
    post puzzle_feedback_path(puzzle), params: { body: "Good", missing_answers: "hue, shade" }
    fb = PuzzleFeedback.find_by(puzzle: puzzle, user: users(:tester_user))
    assert_equal "hue, shade", fb.missing_answers
  end

  test "blank body is rejected" do
    sign_in users(:tester_user)
    post puzzle_feedback_path(puzzles(:today_daily)), params: { body: "   " }
    assert_equal 0, PuzzleFeedback.where(user: users(:tester_user)).count
  end

  test "submitting twice updates existing feedback" do
    sign_in users(:tester_user)
    puzzle = puzzles(:today_daily)
    post puzzle_feedback_path(puzzle), params: { body: "First take" }
    post puzzle_feedback_path(puzzle), params: { body: "Updated take", missing_answers: "hue" }
    assert_equal 1, PuzzleFeedback.where(puzzle: puzzle, user: users(:tester_user)).count
    fb = PuzzleFeedback.find_by(puzzle: puzzle, user: users(:tester_user))
    assert_equal "Updated take", fb.body
    assert_equal "hue", fb.missing_answers
  end

  test "non-tester signed-in user can also submit feedback" do
    sign_in users(:alice)
    post puzzle_feedback_path(puzzles(:today_daily)), params: { body: "Nice" }
    assert_redirected_to :back
  end
end
