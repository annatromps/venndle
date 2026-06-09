require "test_helper"

class PuzzlesControllerTest < ActionDispatch::IntegrationTest
  # ── daily ────────────────────────────────────────────────────────────────────

  test "daily redirects to latest daily number" do
    get daily_path
    assert_response :redirect
    assert_match %r{/daily\d+}, response.location
  end

  # ── index ─────────────────────────────────────────────────────────────────────

  test "index is accessible to guests" do
    get puzzles_path
    assert_response :success
  end

  test "index default filter shows published user-created puzzles" do
    get puzzles_path
    assert_response :success
    assert_includes response.body, puzzles(:community_puzzle).title
  end

  test "index my filter returns only signed-in user puzzles" do
    sign_in users(:bob)
    get puzzles_path(filter: "my")
    assert_includes response.body, puzzles(:community_puzzle).title
    assert_not_includes response.body, puzzles(:past_daily).title
  end

  test "index my filter returns nothing for guest" do
    get puzzles_path(filter: "my")
    assert_response :success
  end

  test "index sort by popular is accepted" do
    get puzzles_path(sort: "popular")
    assert_response :success
  end

  test "index sort by top_rated is accepted" do
    get puzzles_path(sort: "top_rated")
    assert_response :success
  end

  test "index rejects unknown sort falls back to newest" do
    get puzzles_path(sort: "bogus")
    assert_response :success
  end

  # ── practice ─────────────────────────────────────────────────────────────────

  test "practice redirects to root when no practice puzzle exists" do
    get practice_path
    assert_redirected_to root_path
  end

  # ── create ───────────────────────────────────────────────────────────────────

  test "create saves a new user puzzle" do
    sign_in users(:alice)
    assert_difference "Puzzle.count", 1 do
      post puzzles_path, params: { puzzle: {
        label_a: "fruit", label_b: "vehicles", label_c: "colors",
        words_a: "apple\ngrape\npeach",
        words_b: "car\ntruck\nbike",
        words_c: "red\nblue\ngreen",
        words_ab: "mango", words_ac: "cherry", words_bc: "lime", words_abc: "watermelon"
      } }
    end
    puzzle = Puzzle.order(:created_at).last
    assert_equal "user", puzzle.puzzle_type
    assert_equal users(:alice), puzzle.user
  end

  test "create auto-generates title when blank" do
    sign_in users(:alice)
    post puzzles_path, params: { puzzle: {
      label_a: "fruit", label_b: "vehicles", label_c: "colors",
      words_a: "apple", words_b: "car", words_c: "red",
      words_ab: "mango", words_ac: "cherry", words_bc: "lime", words_abc: "watermelon"
    } }
    puzzle = Puzzle.order(:created_at).last
    assert puzzle.title.present?
  end

  test "create requires sign in" do
    post puzzles_path, params: { puzzle: { label_a: "x", label_b: "y", label_c: "z" } }
    assert_redirected_to new_user_session_path
  end

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

  # ── flexible matching ─────────────────────────────────────────────────────────

  test "case-insensitive guess is accepted" do
    sign_in users(:bob)
    puzzle = puzzles(:past_daily)
    post puzzle_guess_path(puzzle), params: { label: "a", guess: "YELLOW" }, as: :json
    assert JSON.parse(response.body)["correct"]
  end

  test "guess with leading/trailing whitespace is accepted" do
    sign_in users(:bob)
    puzzle = puzzles(:past_daily)
    post puzzle_guess_path(puzzle), params: { label: "a", guess: "  yellow  " }, as: :json
    assert JSON.parse(response.body)["correct"]
  end

  test "guess with double internal spaces is accepted" do
    sign_in users(:bob)
    puzzle = puzzles(:past_daily)
    post puzzle_guess_path(puzzle), params: { label: "c", guess: "round" }, as: :json
    assert JSON.parse(response.body)["correct"]
  end

  test "plural of answer is accepted" do
    sign_in users(:bob)
    puzzle = puzzles(:today_daily)
    # label_b is "animals" — singular "animal" should also be accepted
    post puzzle_guess_path(puzzle), params: { label: "b", guess: "animal" }, as: :json
    assert JSON.parse(response.body)["correct"]
  end

  test "singular of plural answer is accepted" do
    sign_in users(:bob)
    puzzle = puzzles(:today_daily)
    # label_a is "colors" — "color" should also match
    post puzzle_guess_path(puzzle), params: { label: "a", guess: "color" }, as: :json
    assert JSON.parse(response.body)["correct"]
  end

  test "guess contained in answer phrase is accepted" do
    sign_in users(:bob)
    puzzle = puzzles(:community_puzzle)
    # label_a is "transport" — stored answer "transportation" contains "transport"
    # Rule: if any word of the answer matches a form of the guess
    post puzzle_guess_path(puzzle), params: { label: "a", guess: "transport" }, as: :json
    assert JSON.parse(response.body)["correct"]
  end

  test "answer contained in guess phrase is accepted" do
    sign_in users(:bob)
    puzzle = puzzles(:today_daily)
    # label_c is "foods" — "types of food" should be accepted because "food" is a form of "foods"
    post puzzle_guess_path(puzzle), params: { label: "c", guess: "types of food" }, as: :json
    assert JSON.parse(response.body)["correct"]
  end

  test "board word guess returns board_word true and correct false" do
    sign_in users(:bob)
    puzzle = puzzles(:past_daily)
    # "minion" is in words_a — a board word
    post puzzle_guess_path(puzzle), params: { label: "a", guess: "minion" }, as: :json
    data = JSON.parse(response.body)
    assert_not data["correct"]
    assert data["board_word"]
  end

  # ── fuzzy matching: direct substring both directions ─────────────────────────

  test "direction A: answer contained within longer guess is accepted" do
    sign_in users(:bob)
    puzzle = puzzles(:past_daily)
    # label_a is "yellow" — "being quite yellow" should match because "yellow" is in the guess
    post puzzle_guess_path(puzzle), params: { label: "a", guess: "being quite yellow" }, as: :json
    assert JSON.parse(response.body)["correct"]
  end

  test "direction B: guess contained within longer answer is accepted" do
    sign_in users(:bob)
    puzzle = puzzles(:past_daily)
    # accepted_answers_b includes "pointed" — guessing "point" should match via word forms
    # and "sharp" is the label — guessing "sharp things" should match (label in guess)
    post puzzle_guess_path(puzzle), params: { label: "b", guess: "sharp things" }, as: :json
    assert JSON.parse(response.body)["correct"]
  end

  # ── reset_session ────────────────────────────────────────────────────────────

  test "admin can reset their own game session" do
    admin = users(:admin_user)
    puzzle = puzzles(:past_daily)
    GameSession.create!(user: admin, puzzle: puzzle, completed: true,
      solved_a: true, solved_b: true, solved_c: true,
      attempts_a: 1, attempts_b: 1, attempts_c: 1)
    Attempt.create!(user: admin, puzzle: puzzle, label: "a", guess: "yellow", correct: true)

    sign_in admin
    delete puzzle_reset_session_path(puzzle)

    assert_redirected_to puzzle_path(puzzle)
    assert_equal 0, GameSession.where(user: admin, puzzle: puzzle).count
    assert_equal 0, Attempt.where(user: admin, puzzle: puzzle).count
  end

  test "non-admin cannot reset session" do
    sign_in users(:alice)
    puzzle = puzzles(:past_daily)
    delete puzzle_reset_session_path(puzzle)
    assert_response :forbidden
  end

  test "guest cannot reset session" do
    puzzle = puzzles(:past_daily)
    delete puzzle_reset_session_path(puzzle)
    assert_response :forbidden
  end

  test "reset does not affect other users sessions" do
    admin = users(:admin_user)
    puzzle = puzzles(:past_daily)
    alice_session = game_sessions(:alice_past_completed)

    sign_in admin
    delete puzzle_reset_session_path(puzzle)

    assert GameSession.exists?(alice_session.id)
  end

  # ── tester feedback box ───────────────────────────────────────────────────────

  test "tester sees accepted answers on daily puzzle page" do
    sign_in users(:tester_user)
    puzzle = puzzles(:today_daily)
    day_num = puzzle.day_number
    get "/daily#{day_num}"
    assert_response :success
    assert_match puzzle.label_a, response.body
    assert_match puzzle.accepted_answers_a.last, response.body
  end

  test "tester sees missing answers textarea on daily puzzle page" do
    sign_in users(:tester_user)
    puzzle = puzzles(:today_daily)
    day_num = puzzle.day_number
    get "/daily#{day_num}"
    assert_response :success
    assert_match(/name="missing_answers"/, response.body)
  end

  test "non-tester does not see tester feedback box on daily puzzle page" do
    sign_in users(:alice)
    puzzle = puzzles(:today_daily)
    day_num = puzzle.day_number
    get "/daily#{day_num}"
    assert_response :success
    assert_no_match(/Tester feedback/i, response.body)
  end

  # ── script block JSON escaping ────────────────────────────────────────────────

  # Guards against to_json without .html_safe in <script> blocks — ERB HTML-escapes
  # double-quotes to &quot; which is a JS SyntaxError that silently kills the whole block.

  test "completed daily puzzle page for guest has no html-escaped JSON in script blocks" do
    puzzle = puzzles(:today_daily)
    post puzzle_guess_path(puzzle), params: { label: "a", guess: "colors" }, as: :json
    post puzzle_guess_path(puzzle), params: { label: "b", guess: "animals" }, as: :json
    post puzzle_guess_path(puzzle), params: { label: "c", guess: "foods" }, as: :json

    day_num = puzzle.day_number
    get "/daily#{day_num}"
    assert_response :success

    response.body.scan(/<script[^>]*>(.*?)<\/script>/m).each do |match|
      assert_no_match(/&quot;/, match[0],
        "HTML-escaped quote (&quot;) found in <script> block — add .html_safe to .to_json calls in ERB script contexts")
    end
  end

  test "active daily puzzle page for guest with prior attempts has no html-escaped JSON in script blocks" do
    puzzle = puzzles(:today_daily)
    # "red" is a board word — rejected without an AI call
    post puzzle_guess_path(puzzle), params: { label: "b", guess: "red" }, as: :json

    day_num = puzzle.day_number
    get "/daily#{day_num}"
    assert_response :success

    response.body.scan(/<script[^>]*>(.*?)<\/script>/m).each do |match|
      assert_no_match(/&quot;/, match[0],
        "HTML-escaped quote (&quot;) found in <script> block — add .html_safe to .to_json calls in ERB script contexts")
    end
  end
end
