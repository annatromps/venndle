require "test_helper"
require "ostruct"

class ApplicationHelperTest < ActionView::TestCase
  include ApplicationHelper

  # game_id_for

  test "game_id_for returns date string for today's daily" do
    puzzle = puzzles(:today_daily)
    result = game_id_for(puzzle)
    assert_equal "daily_#{Date.today.strftime('%Y-%m-%d')}", result
  end

  test "game_id_for returns archive_N for past daily" do
    puzzle = puzzles(:past_daily)
    result = game_id_for(puzzle)
    assert_match(/\Aarchive_\d+\z/, result)
  end

  test "game_id_for archive number matches puzzle day_number" do
    puzzle = puzzles(:past_daily)
    result = game_id_for(puzzle)
    assert_equal "archive_#{puzzle.day_number}", result
  end

  test "game_id_for returns community_userN for user puzzle" do
    puzzle = puzzles(:community_puzzle)
    result = game_id_for(puzzle)
    assert_equal "community_user#{puzzle.id}", result
  end

  test "game_id_for future daily uses date not archive number" do
    puzzle = puzzles(:future_daily)
    result = game_id_for(puzzle)
    assert_match(/\Adaily_\d{4}-\d{2}-\d{2}\z/, result)
  end

  # build_share_string_for

  test "share string contains venndle.app URL for daily puzzle" do
    gs = game_sessions(:alice_past_completed)
    puzzle = puzzles(:past_daily)
    result = build_share_string_for(gs, puzzle)
    assert_match %r{https://venndle\.app}, result
  end

  test "share string last line is the full URL" do
    gs = game_sessions(:alice_past_completed)
    puzzle = puzzles(:past_daily)
    result = build_share_string_for(gs, puzzle)
    assert_equal "https://venndle.app", result.lines.last.strip
  end

  test "share string contains venndle.app/ID for community puzzle" do
    gs = game_sessions(:alice_community_gave_up)
    puzzle = puzzles(:community_puzzle)
    result = build_share_string_for(gs, puzzle)
    assert_match %r{venndle\.app/#{puzzle.id}}, result
  end

  test "share string shows correct miss count" do
    gs = game_sessions(:alice_past_completed)
    # alice_past_completed: attempts_a=2 solved_a=true -> 1 miss, attempts_b=1 solved_b=true -> 0, attempts_c=3 solved_c=true -> 2
    result = build_share_string_for(gs, puzzles(:past_daily))
    lines = result.lines.map(&:strip)
    a_line = lines.find { |l| l.start_with?("A ") }
    assert_match(/A ❌✅/, a_line)
  end

  test "share string shows gave_up flag" do
    gs = game_sessions(:alice_community_gave_up)
    result = build_share_string_for(gs, puzzles(:community_puzzle))
    lines = result.lines.map(&:strip)
    b_line = lines.find { |l| l.start_with?("B ") }
    assert_match(/🏳️/, b_line)
  end

  test "share string shows hint emoji when hints used" do
    gs = game_sessions(:alice_community_gave_up)
    # hints_a = 2
    result = build_share_string_for(gs, puzzles(:community_puzzle))
    lines = result.lines.map(&:strip)
    a_line = lines.find { |l| l.start_with?("A ") }
    assert_match(/💡💡/, a_line)
  end

  test "share string title is daily format for daily puzzle" do
    gs = game_sessions(:alice_past_completed)
    puzzle = puzzles(:past_daily)
    result = build_share_string_for(gs, puzzle)
    assert result.start_with?("Venndle Daily —")
  end

  test "share string title uses puzzle title for community puzzle" do
    gs = game_sessions(:alice_community_gave_up)
    puzzle = puzzles(:community_puzzle)
    result = build_share_string_for(gs, puzzle)
    assert result.start_with?("Community Puzzle")
  end

  # circle_order_for

  test "circle_order_for returns labels in first-seen attempt order" do
    attempts = [
      OpenStruct.new(label: "c"),
      OpenStruct.new(label: "c"),
      OpenStruct.new(label: "a"),
      OpenStruct.new(label: "b")
    ]
    assert_equal %w[c a b], circle_order_for(attempts)
  end

  test "circle_order_for fills missing labels at the end" do
    attempts = [ OpenStruct.new(label: "b") ]
    result = circle_order_for(attempts)
    assert_equal "b", result.first
    assert_includes result, "a"
    assert_includes result, "c"
    assert_equal 3, result.length
  end

  test "circle_order_for falls back to abc when attempts empty" do
    assert_equal %w[a b c], circle_order_for([])
  end

  # build_share_string_for with custom circle_order

  test "share string respects custom circle_order" do
    gs = game_sessions(:alice_past_completed)
    puzzle = puzzles(:past_daily)
    result = build_share_string_for(gs, puzzle, circle_order: %w[c b a])
    lines = result.lines.map(&:strip).reject { |l| l.empty? }
    score_lines = lines[1..-2]   # strip title and URL
    assert score_lines.first.start_with?("C "), "First score line should be C, got: #{score_lines.first}"
    assert score_lines[1].start_with?("B ")
    assert score_lines.last.start_with?("A ")
  end
end
