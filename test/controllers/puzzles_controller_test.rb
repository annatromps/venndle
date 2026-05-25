require "test_helper"

class PuzzlesControllerTest < ActionDispatch::IntegrationTest
  # ── archive ─────────────────────────────────────────────────────────────────

  test "archive accessible without sign in" do
    get archive_path
    assert_response :success
  end

  test "archive shows today and past puzzles to guests" do
    get archive_path
    assert_includes response.body, "Past Daily"
    assert_includes response.body, "Today Daily"
  end

  test "archive hides future puzzles from regular users" do
    sign_in users(:alice)
    get archive_path
    assert_not_includes response.body, "Future Daily"
  end

  test "archive shows future puzzles to admin" do
    sign_in users(:admin_user)
    get archive_path
    assert_includes response.body, "Future Daily"
  end

  # ── show_by_daily_number ────────────────────────────────────────────────────

  test "today's daily accessible to guest" do
    puzzle = puzzles(:today_daily)
    day_num = puzzle.day_number
    get "/daily#{day_num}"
    assert_response :success
  end

  test "past daily redirects guest to sign in" do
    puzzle = puzzles(:past_daily)
    day_num = puzzle.day_number
    get "/daily#{day_num}"
    assert_redirected_to new_user_session_path
  end

  test "past daily accessible to signed-in user" do
    sign_in users(:alice)
    puzzle = puzzles(:past_daily)
    day_num = puzzle.day_number
    get "/daily#{day_num}"
    assert_response :success
  end

  test "future daily redirects non-admin" do
    sign_in users(:alice)
    puzzle = puzzles(:future_daily)
    day_num = puzzle.day_number
    get "/daily#{day_num}"
    assert_redirected_to archive_path
  end

  test "future daily accessible to admin" do
    sign_in users(:admin_user)
    puzzle = puzzles(:future_daily)
    day_num = puzzle.day_number
    get "/daily#{day_num}"
    assert_response :success
  end

  test "non-existent daily number redirects to archive" do
    sign_in users(:alice)
    get "/daily9999"
    assert_redirected_to archive_path
  end

  # ── new / create ─────────────────────────────────────────────────────────────

  test "new redirects guest to sign in" do
    get new_puzzle_path
    assert_redirected_to new_user_session_path
  end

  test "new accessible when signed in" do
    sign_in users(:alice)
    get new_puzzle_path
    assert_response :success
  end

  test "create redirects guest to sign in" do
    post puzzles_path, params: { puzzle: { label_a: "x", label_b: "y", label_c: "z" } }
    assert_redirected_to new_user_session_path
  end

  # ── hint ─────────────────────────────────────────────────────────────────────

  test "hint returns first letter of label at position 0" do
    sign_in users(:alice)
    puzzle = puzzles(:past_daily)
    post puzzle_hint_path(puzzle), params: { label: "a", revealed_count: 0 }, as: :json
    assert_response :success
    data = JSON.parse(response.body)
    assert_equal puzzle.label_a[0].upcase, data["letter"].upcase
    assert_equal puzzle.label_a.length, data["total_length"]
    assert_equal 0, data["position"]
  end

  test "hint returns correct letter at subsequent positions" do
    sign_in users(:alice)
    puzzle = puzzles(:past_daily)
    # label_a is "yellow" — test position 2 = "l"
    post puzzle_hint_path(puzzle), params: { label: "a", revealed_count: 2 }, as: :json
    assert_response :success
    data = JSON.parse(response.body)
    assert_equal puzzle.label_a[2], data["letter"]
  end

  test "hint returns done when revealed_count equals label length" do
    sign_in users(:alice)
    puzzle = puzzles(:past_daily)
    post puzzle_hint_path(puzzle), params: { label: "a", revealed_count: puzzle.label_a.length }, as: :json
    assert_response :success
    data = JSON.parse(response.body)
    assert data["done"]
  end

  test "hint returns done when revealed_count exceeds label length" do
    sign_in users(:alice)
    puzzle = puzzles(:past_daily)
    post puzzle_hint_path(puzzle), params: { label: "a", revealed_count: 999 }, as: :json
    assert_response :success
    assert JSON.parse(response.body)["done"]
  end

  test "hint with invalid label returns 400" do
    sign_in users(:alice)
    post puzzle_hint_path(puzzles(:past_daily)), params: { label: "z", revealed_count: 0 }, as: :json
    assert_response :bad_request
  end

  test "hint sequential calls reveal correct letters" do
    sign_in users(:bob)
    puzzle = puzzles(:past_daily)
    label_text = puzzle.label_a  # "yellow"
    label_text.each_char.with_index do |char, i|
      post puzzle_hint_path(puzzle), params: { label: "a", revealed_count: i }, as: :json
      assert_response :success
      data = JSON.parse(response.body)
      assert_equal char, data["letter"], "Position #{i} should be '#{char}'"
    end
  end

  # ── give_up ──────────────────────────────────────────────────────────────────

  test "give_up marks label as solved and gave_up" do
    sign_in users(:bob)
    puzzle = puzzles(:past_daily)
    post puzzle_give_up_path(puzzle), params: { label: "a" }, as: :json
    assert_response :success
    data = JSON.parse(response.body)
    assert_equal puzzle.label_a, data["official_label"]

    gs = GameSession.find_by(user: users(:bob), puzzle: puzzle)
    assert gs.solved_a?
    assert gs.gave_up_a?
  end

  test "give_up returns already_solved when label already solved" do
    sign_in users(:alice)
    # alice_past_completed already has solved_a: true
    post puzzle_give_up_path(puzzles(:past_daily)), params: { label: "a" }, as: :json
    assert_response :success
    data = JSON.parse(response.body)
    assert data["already_solved"]
  end

  test "give_up with invalid label returns 400" do
    sign_in users(:alice)
    post puzzle_give_up_path(puzzles(:past_daily)), params: { label: "z" }, as: :json
    assert_response :bad_request
  end

  test "give_up marks session completed when all labels solved" do
    sign_in users(:bob)
    puzzle = puzzles(:past_daily)
    # bob_past_in_progress has nothing solved — give up all three
    %w[a b c].each do |label|
      post puzzle_give_up_path(puzzle), params: { label: label }, as: :json
    end
    gs = GameSession.find_by(user: users(:bob), puzzle: puzzle)
    assert gs.completed?
  end

  # ── guess ─────────────────────────────────────────────────────────────────────

  test "correct guess (from accepted_answers) returns correct true" do
    sign_in users(:bob)
    puzzle = puzzles(:past_daily)
    # "yellow" is in accepted_answers_a — no AI call needed
    post puzzle_guess_path(puzzle), params: { label: "a", guess: "yellow" }, as: :json
    assert_response :success
    data = JSON.parse(response.body)
    assert data["correct"]
    assert data["solved"]["a"]
  end

  test "incorrect guess (puzzle word) returns correct false" do
    sign_in users(:bob)
    puzzle = puzzles(:past_daily)
    # "minion" is in words_a — all_puzzle_words check sets correct = false, no AI call
    post puzzle_guess_path(puzzle), params: { label: "b", guess: "minion" }, as: :json
    assert_response :success
    data = JSON.parse(response.body)
    assert_not data["correct"]
  end

  test "blank guess returns 400" do
    sign_in users(:alice)
    post puzzle_guess_path(puzzles(:past_daily)), params: { label: "a", guess: "" }, as: :json
    assert_response :bad_request
  end

  test "guess with invalid label returns 400" do
    sign_in users(:alice)
    post puzzle_guess_path(puzzles(:past_daily)), params: { label: "z", guess: "test" }, as: :json
    assert_response :bad_request
  end

  test "duplicate guess returns duplicate true" do
    sign_in users(:alice)
    puzzle = puzzles(:past_daily)
    # alice already has an attempt with guess "yellow" (from fixture alice_correct_a)
    post puzzle_guess_path(puzzle), params: { label: "a", guess: "yellow" }, as: :json
    assert_response :success
    data = JSON.parse(response.body)
    assert data["duplicate"]
  end

  test "correct guess increments attempts and marks solved" do
    sign_in users(:bob)
    puzzle = puzzles(:past_daily)
    gs_before = game_sessions(:bob_past_in_progress)
    attempts_before = gs_before.attempts_a

    post puzzle_guess_path(puzzle), params: { label: "a", guess: "yellow" }, as: :json

    gs = GameSession.find_by(user: users(:bob), puzzle: puzzle)
    assert_equal attempts_before + 1, gs.attempts_a
    assert gs.solved_a?
  end

  test "completing all three labels marks session completed" do
    sign_in users(:bob)
    puzzle = puzzles(:past_daily)
    post puzzle_guess_path(puzzle), params: { label: "a", guess: "yellow" }, as: :json
    post puzzle_guess_path(puzzle), params: { label: "b", guess: "sharp" }, as: :json
    post puzzle_guess_path(puzzle), params: { label: "c", guess: "round" }, as: :json

    gs = GameSession.find_by(user: users(:bob), puzzle: puzzle)
    assert gs.completed?
    last_response = JSON.parse(response.body)
    assert last_response["completed"]
  end

  test "share_string in guess response includes venndle.app URL" do
    sign_in users(:bob)
    puzzle = puzzles(:past_daily)
    post puzzle_guess_path(puzzle), params: { label: "a", guess: "yellow" }, as: :json
    data = JSON.parse(response.body)
    assert_match %r{venndle\.app}, data["share_string"]
  end
end
