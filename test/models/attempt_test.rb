require "test_helper"

class AttemptTest < ActiveSupport::TestCase
  test "valid with correct attributes" do
    a = Attempt.new(user: users(:alice), puzzle: puzzles(:past_daily), label: "a", guess: "yellow", correct: true)
    assert a.valid?
  end

  test "invalid without guess" do
    a = Attempt.new(user: users(:alice), puzzle: puzzles(:past_daily), label: "a", correct: false)
    assert_not a.valid?
    assert a.errors[:guess].any?
  end

  test "invalid with bad label" do
    a = Attempt.new(user: users(:alice), puzzle: puzzles(:past_daily), label: "z", guess: "test", correct: false)
    assert_not a.valid?
    assert a.errors[:label].any?
  end

  test "valid for all correct label values" do
    %w[a b c].each do |label|
      a = Attempt.new(user: users(:alice), puzzle: puzzles(:past_daily), label: label, guess: "test", correct: false)
      assert a.valid?, "label '#{label}' should be valid"
    end
  end
end
