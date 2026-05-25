require "test_helper"

class GameSessionTest < ActiveSupport::TestCase
  test "solved_all? returns false when none solved" do
    gs = game_sessions(:bob_past_in_progress)
    assert_not gs.solved_all?
  end

  test "solved_all? returns true when all three solved" do
    gs = game_sessions(:alice_past_completed)
    assert gs.solved_all?
  end

  test "solved_all? returns false when only some solved" do
    gs = game_sessions(:alice_past_completed).dup
    gs.solved_c = false
    assert_not gs.solved_all?
  end

  test "attempts_for returns correct attempt count for each label" do
    gs = game_sessions(:alice_past_completed)
    assert_equal 2, gs.attempts_for("a")
    assert_equal 1, gs.attempts_for("b")
    assert_equal 3, gs.attempts_for("c")
  end

  test "solved_for? returns correct solve state" do
    gs = game_sessions(:alice_past_completed)
    assert gs.solved_for?("a")
    assert gs.solved_for?("b")
    assert gs.solved_for?("c")
  end

  test "solved_for? returns false when unsolved" do
    gs = game_sessions(:bob_past_in_progress)
    assert_not gs.solved_for?("a")
    assert_not gs.solved_for?("b")
    assert_not gs.solved_for?("c")
  end

  test "belongs to user and puzzle" do
    gs = game_sessions(:alice_past_completed)
    assert_equal users(:alice), gs.user
    assert_equal puzzles(:past_daily), gs.puzzle
  end
end
