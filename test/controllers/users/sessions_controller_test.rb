require "test_helper"

class Users::SessionsControllerTest < ActionDispatch::IntegrationTest
  test "sign in succeeds" do
    post user_session_path, params: { user: { email: users(:alice).email, password: "password" } }
    assert_redirected_to root_path
  end

  test "completed guest session is transferred on sign in" do
    puzzle = puzzles(:today_daily)
    # Simulate a guest playing and completing a puzzle
    post puzzle_guess_path(puzzle), params: { label: "a", guess: "colors" }, as: :json
    post puzzle_guess_path(puzzle), params: { label: "b", guess: "animals" }, as: :json
    post puzzle_guess_path(puzzle), params: { label: "c", guess: "foods" }, as: :json

    assert_difference "GameSession.count", 1 do
      post user_session_path, params: { user: { email: users(:bob).email, password: "password" } }
    end

    gs = GameSession.find_by(user: users(:bob), puzzle: puzzle)
    assert_not_nil gs
    assert gs.completed?
    assert gs.solved_a?
    assert gs.solved_b?
    assert gs.solved_c?
  end

  test "incomplete guest session is not transferred on sign in" do
    puzzle = puzzles(:today_daily)
    post puzzle_guess_path(puzzle), params: { label: "a", guess: "colors" }, as: :json
    # only one circle solved — not completed

    assert_no_difference "GameSession.count" do
      post user_session_path, params: { user: { email: users(:bob).email, password: "password" } }
    end
  end

  test "guest session is not transferred if game session already exists" do
    puzzle = puzzles(:today_daily)
    post puzzle_guess_path(puzzle), params: { label: "a", guess: "colors" }, as: :json
    post puzzle_guess_path(puzzle), params: { label: "b", guess: "animals" }, as: :json
    post puzzle_guess_path(puzzle), params: { label: "c", guess: "foods" }, as: :json

    # alice already has a completed session for past_daily; here bob has none for today_daily
    # but let's create one manually to test the duplicate guard
    GameSession.create!(user: users(:bob), puzzle: puzzle, completed: true,
      solved_a: true, solved_b: true, solved_c: true,
      attempts_a: 1, attempts_b: 1, attempts_c: 1)

    assert_no_difference "GameSession.count" do
      post user_session_path, params: { user: { email: users(:bob).email, password: "password" } }
    end
  end
end
