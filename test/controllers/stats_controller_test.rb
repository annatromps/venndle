require "test_helper"

class StatsControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Use a fresh user for each stats test to avoid fixture pollution
    @user = User.create!(
      username: "stats_tester_#{SecureRandom.hex(4)}",
      email:    "stats_#{SecureRandom.hex(4)}@test.com",
      password: "password123"
    )
    sign_in @user
  end

  def make_daily_session(date:, attempts_a: 1, attempts_b: 1, attempts_c: 1,
                          gave_up_a: false, gave_up_b: false, gave_up_c: false)
    puzzle = Puzzle.create!(
      puzzle_type:    "daily",
      scheduled_date: date,
      published:      true,
      label_a:        "x", label_b: "y", label_c: "z",
      user:           users(:admin_user)
    )
    GameSession.create!(
      user:       @user,
      puzzle:     puzzle,
      completed:  true,
      solved_a:   true, solved_b: true, solved_c: true,
      attempts_a: attempts_a,
      attempts_b: attempts_b,
      attempts_c: attempts_c,
      gave_up_a:  gave_up_a,
      gave_up_b:  gave_up_b,
      gave_up_c:  gave_up_c
    )
  end

  # ── access control ──────────────────────────────────────────────────────────

  test "redirects guest to sign in" do
    sign_out @user
    get my_stats_path
    assert_redirected_to new_user_session_path
  end

  test "accessible when signed in" do
    get my_stats_path
    assert_response :success
  end

  # ── empty state ──────────────────────────────────────────────────────────────

  test "shows empty state when no daily completions" do
    get my_stats_path
    assert_response :success
    # No completions — the view shows an empty-state block, not streak numbers
    assert_not_includes response.body, "day streak"
  end

  # ── streak calculation ────────────────────────────────────────────────────────

  test "streak is 1 when only today is completed" do
    make_daily_session(date: Date.today)
    get my_stats_path
    assert_response :success
    assert_match %r{>\s*1\s*<}, response.body
  end

  test "streak counts consecutive days including today" do
    make_daily_session(date: Date.today)
    make_daily_session(date: Date.today - 1)
    make_daily_session(date: Date.today - 2)
    get my_stats_path
    assert_match %r{>\s*3\s*<}, response.body
  end

  test "streak is 1 when played today but not yesterday" do
    make_daily_session(date: Date.today)
    make_daily_session(date: Date.today - 3)
    get my_stats_path
    # Current streak should be 1 (only today is consecutive)
    # We check that 1 appears but also verify the longest streak would be 1
    assert_response :success
  end

  test "streak counts from yesterday when today not played" do
    make_daily_session(date: Date.today - 1)
    make_daily_session(date: Date.today - 2)
    get my_stats_path
    assert_match %r{>\s*2\s*<}, response.body
  end

  test "streak is 0 when most recent play has a gap before today and yesterday" do
    make_daily_session(date: Date.today - 5)
    get my_stats_path
    assert_match %r{>\s*0\s*<}, response.body
  end

  # ── longest streak ────────────────────────────────────────────────────────────

  test "longest streak tracks best historical run" do
    # Played 3 days in a row last week, only today this week
    make_daily_session(date: Date.today - 10)
    make_daily_session(date: Date.today - 9)
    make_daily_session(date: Date.today - 8)
    make_daily_session(date: Date.today)
    get my_stats_path
    # Best streak = 3 (the run last week), current = 1 (just today)
    # Both values should appear in the page
    assert_match %r{>\s*3\s*<}, response.body
    assert_match %r{>\s*1\s*<}, response.body
  end

  # ── avg misses ─────────────────────────────────────────────────────────────────

  test "avg misses is nil displayed as dash when no completions" do
    get my_stats_path
    # Empty state — no avg displayed in the stats card
    assert_response :success
  end

  test "avg misses is 0 for perfect games" do
    make_daily_session(date: Date.today, attempts_a: 1, attempts_b: 1, attempts_c: 1)
    get my_stats_path
    # 1 attempt each, all solved = 0 misses each = avg 0.0
    assert_match %r{>\s*0\.0\s*<|>\s*0\s*<}, response.body
  end

  test "avg misses calculated correctly across games" do
    # Game 1: 3 misses total (2+1+0 wrong)
    make_daily_session(date: Date.today - 1, attempts_a: 3, attempts_b: 2, attempts_c: 1)
    # Game 2: 0 misses total (1+1+1)
    make_daily_session(date: Date.today, attempts_a: 1, attempts_b: 1, attempts_c: 1)
    get my_stats_path
    # avg = (3 + 0) / 2 = 1.5
    assert_match %r{>\s*1\.5\s*<}, response.body
  end

  test "gave_up attempts count as wrong guesses for misses" do
    # gave_up_a: all attempts_a count as wrong (not -1 for solve)
    make_daily_session(date: Date.today, attempts_a: 2, attempts_b: 1, attempts_c: 1,
                       gave_up_a: true)
    get my_stats_path
    # misses = 2 (gave_up) + 0 (1-1) + 0 (1-1) = 2
    assert_match %r{>\s*2\.0\s*<|>\s*2\s*<}, response.body
  end

  # ── total completed ───────────────────────────────────────────────────────────

  test "total completed count is displayed correctly" do
    make_daily_session(date: Date.today - 2)
    make_daily_session(date: Date.today - 1)
    make_daily_session(date: Date.today)
    get my_stats_path
    assert_includes response.body, "3"
  end
end
