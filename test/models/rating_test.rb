require "test_helper"

class RatingTest < ActiveSupport::TestCase
  test "valid with score in range" do
    (1..5).each do |n|
      r = Rating.new(puzzle: puzzles(:community_puzzle), user: users(:alice), score: n)
      assert r.valid?, "score #{n} should be valid"
    end
  end

  test "invalid with score below 1" do
    r = Rating.new(puzzle: puzzles(:community_puzzle), user: users(:alice), score: 0)
    assert_not r.valid?
    assert r.errors[:score].any?
  end

  test "invalid with score above 5" do
    r = Rating.new(puzzle: puzzles(:community_puzzle), user: users(:alice), score: 6)
    assert_not r.valid?
    assert r.errors[:score].any?
  end

  test "user can only rate a puzzle once" do
    Rating.create!(puzzle: puzzles(:community_puzzle), user: users(:alice), score: 3)
    duplicate = Rating.new(puzzle: puzzles(:community_puzzle), user: users(:alice), score: 4)
    assert_not duplicate.valid?
    assert duplicate.errors[:user_id].any?
  end

  test "same user can rate different puzzles" do
    Rating.create!(puzzle: puzzles(:community_puzzle), user: users(:alice), score: 3)
    r = Rating.new(puzzle: puzzles(:today_daily), user: users(:alice), score: 5)
    assert r.valid?
  end
end
