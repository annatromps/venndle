require "test_helper"

class PuzzleTest < ActiveSupport::TestCase
  # Validations

  test "valid with all required fields" do
    assert puzzles(:past_daily).valid?
  end

  test "invalid without label_a" do
    p = Puzzle.new(puzzle_type: "daily", label_b: "x", label_c: "y", user: users(:alice))
    assert_not p.valid?
    assert p.errors[:label_a].any?
  end

  test "invalid without label_b" do
    p = Puzzle.new(puzzle_type: "daily", label_a: "x", label_c: "y", user: users(:alice))
    assert_not p.valid?
    assert p.errors[:label_b].any?
  end

  test "invalid without label_c" do
    p = Puzzle.new(puzzle_type: "daily", label_a: "x", label_b: "y", user: users(:alice))
    assert_not p.valid?
    assert p.errors[:label_c].any?
  end

  test "invalid with unknown puzzle_type" do
    p = puzzles(:past_daily).dup
    p.puzzle_type = "unknown"
    assert_not p.valid?
    assert p.errors[:puzzle_type].any?
  end

  test "valid puzzle types are daily user admin" do
    %w[daily user admin].each do |type|
      p = Puzzle.new(puzzle_type: type, label_a: "x", label_b: "y", label_c: "z", user: users(:alice))
      assert p.valid?, "Expected puzzle_type '#{type}' to be valid"
    end
  end

  # Scopes

  test "published scope returns only published puzzles" do
    assert_includes Puzzle.published, puzzles(:past_daily)
    assert_not_includes Puzzle.published, puzzles(:unpublished_puzzle)
  end

  test "daily scope returns only daily type" do
    assert_includes Puzzle.daily, puzzles(:past_daily)
    assert_not_includes Puzzle.daily, puzzles(:community_puzzle)
  end

  test "user_created scope returns only user type" do
    assert_includes Puzzle.user_created, puzzles(:community_puzzle)
    assert_not_includes Puzzle.user_created, puzzles(:past_daily)
  end

  test "admin_created scope returns only admin type" do
    admin_puzzle = Puzzle.create!(
      puzzle_type: "admin", label_a: "x", label_b: "y", label_c: "z",
      user: users(:alice), published: true
    )
    assert_includes Puzzle.admin_created, admin_puzzle
    assert_not_includes Puzzle.admin_created, puzzles(:past_daily)
  end

  # day_number

  test "day_number returns nil for user puzzle" do
    assert_nil puzzles(:community_puzzle).day_number
  end

  test "day_number returns nil for daily without scheduled_date" do
    p = Puzzle.new(puzzle_type: "daily")
    assert_nil p.day_number
  end

  test "day_number returns 1 for the earliest published daily" do
    assert_equal 1, puzzles(:past_daily).day_number
  end

  test "day_number for today is greater than day_number for past" do
    assert puzzles(:today_daily).day_number > puzzles(:past_daily).day_number
  end

  test "future unpublished daily does not increment day_number counts" do
    # future_daily is published but scheduled in the future — it should NOT
    # be counted when computing day_number for past/today puzzles
    past_num  = puzzles(:past_daily).day_number
    today_num = puzzles(:today_daily).day_number
    assert_equal today_num - past_num, 1
  end

  # all_words

  test "all_words aggregates all regions" do
    words = puzzles(:past_daily).all_words
    assert_includes words, "lemon"    # words_abc
    assert_includes words, "minion"   # words_a
    assert_includes words, "mustard"  # words_ab
    assert_includes words, "urchin"   # words_bc
  end

  test "all_words has no duplicates" do
    words = puzzles(:past_daily).all_words
    assert_equal words.uniq.length, words.length
  end

  # all_circle_words_for

  test "all_circle_words_for a includes words from a ab ac abc regions" do
    words = puzzles(:past_daily).all_circle_words_for("a")
    assert_includes words, "minion"    # words_a
    assert_includes words, "mustard"   # words_ab
    assert_includes words, "sun"       # words_ac
    assert_includes words, "lemon"     # words_abc
    assert_not_includes words, "wit"   # words_b only
    assert_not_includes words, "urchin" # words_bc only
  end

  test "all_circle_words_for b includes words from b ab bc abc regions" do
    words = puzzles(:past_daily).all_circle_words_for("b")
    assert_includes words, "wit"       # words_b
    assert_includes words, "mustard"   # words_ab
    assert_includes words, "urchin"    # words_bc
    assert_includes words, "lemon"     # words_abc
    assert_not_includes words, "sun"   # words_ac only
    assert_not_includes words, "earth" # words_c only
  end

  test "all_circle_words_for c includes words from c ac bc abc regions" do
    words = puzzles(:past_daily).all_circle_words_for("c")
    assert_includes words, "earth"     # words_c
    assert_includes words, "sun"       # words_ac
    assert_includes words, "urchin"    # words_bc
    assert_includes words, "lemon"     # words_abc
    assert_not_includes words, "wit"   # words_b only
    assert_not_includes words, "minion" # words_a only
  end

  test "all_circle_words_for with unknown label returns empty array" do
    assert_empty puzzles(:past_daily).all_circle_words_for("z")
  end

  # words_for_region

  test "words_for_region returns correct words" do
    assert_equal puzzles(:past_daily).words_abc, puzzles(:past_daily).words_for_region("abc")
  end

  # dependent destroy

  test "destroying puzzle destroys its game sessions" do
    puzzle = puzzles(:past_daily)
    session_id = game_sessions(:alice_past_completed).id
    puzzle.destroy
    assert_nil GameSession.find_by(id: session_id)
  end
end
