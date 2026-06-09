require "test_helper"

class PuzzleFeedbackTest < ActiveSupport::TestCase
  test "valid with body" do
    fb = PuzzleFeedback.new(puzzle: puzzles(:today_daily), user: users(:tester_user), body: "Looks good")
    assert fb.valid?
  end

  test "invalid without body" do
    fb = PuzzleFeedback.new(puzzle: puzzles(:today_daily), user: users(:tester_user))
    assert_not fb.valid?
    assert fb.errors[:body].any?
  end

  test "user can only submit one feedback per puzzle" do
    PuzzleFeedback.create!(puzzle: puzzles(:today_daily), user: users(:tester_user), body: "First")
    duplicate = PuzzleFeedback.new(puzzle: puzzles(:today_daily), user: users(:tester_user), body: "Second")
    assert_not duplicate.valid?
    assert duplicate.errors[:user_id].any?
  end

  test "same user can submit feedback on different puzzles" do
    PuzzleFeedback.create!(puzzle: puzzles(:today_daily), user: users(:tester_user), body: "First")
    fb = PuzzleFeedback.new(puzzle: puzzles(:past_daily), user: users(:tester_user), body: "Second")
    assert fb.valid?
  end

  test "missing_answers is optional" do
    fb = PuzzleFeedback.new(puzzle: puzzles(:today_daily), user: users(:tester_user), body: "Fine", missing_answers: nil)
    assert fb.valid?
  end
end
