require "test_helper"

class GuestAttemptTest < ActiveSupport::TestCase
  test "correct? returns true when correct is true" do
    a = GuestAttempt.new(label: "a", guess: "yellow", correct: true)
    assert a.correct?
  end

  test "correct? returns false when correct is false" do
    a = GuestAttempt.new(label: "b", guess: "wrong", correct: false)
    assert_not a.correct?
  end

  test "exposes label and guess" do
    a = GuestAttempt.new(label: "c", guess: "round", correct: true)
    assert_equal "c", a.label
    assert_equal "round", a.guess
  end
end
