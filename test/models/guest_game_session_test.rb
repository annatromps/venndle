require "test_helper"

class GuestGameSessionTest < ActiveSupport::TestCase
  def make_session
    {}
  end

  test "initialises with all defaults set to zero or false" do
    session = make_session
    gs = GuestGameSession.find_or_create(session, 1)

    assert_equal false, gs.solved_a?
    assert_equal false, gs.solved_b?
    assert_equal false, gs.solved_c?
    assert_equal false, gs.completed?
    assert_equal 0, gs.attempts_a
    assert_equal 0, gs.attempts_b
    assert_equal 0, gs.attempts_c
    assert_equal false, gs.gave_up_a?
    assert_equal false, gs.gave_up_b?
    assert_equal false, gs.gave_up_c?
    assert_equal false, gs.hint_used_a?
    assert_equal false, gs.hint_used_b?
    assert_equal false, gs.hint_used_c?
    assert_equal 0, gs.hints_a
    assert_equal 0, gs.hints_b
    assert_equal 0, gs.hints_c
  end

  test "find_or_create returns same state for same puzzle_id" do
    session = make_session
    gs1 = GuestGameSession.find_or_create(session, 42)
    gs1.update!(solved_a: true)
    gs2 = GuestGameSession.find_or_create(session, 42)
    assert gs2.solved_a?
  end

  test "different puzzle_ids have independent state" do
    session = make_session
    gs1 = GuestGameSession.find_or_create(session, 1)
    gs1.update!(solved_a: true)
    gs2 = GuestGameSession.find_or_create(session, 2)
    assert_not gs2.solved_a?
  end

  test "increment! increases a counter field" do
    session = make_session
    gs = GuestGameSession.find_or_create(session, 1)
    gs.increment!("attempts_a")
    assert_equal 1, gs.attempts_a
    gs.increment!("attempts_a")
    assert_equal 2, gs.attempts_a
  end

  test "increment! works for hints" do
    session = make_session
    gs = GuestGameSession.find_or_create(session, 1)
    gs.increment!("hints_b")
    assert_equal 1, gs.hints_b
    assert_equal 0, gs.hints_a
  end

  test "update! sets multiple attributes" do
    session = make_session
    gs = GuestGameSession.find_or_create(session, 1)
    gs.update!(solved_a: true, completed: true, gave_up_b: true)
    assert gs.solved_a?
    assert gs.completed?
    assert gs.gave_up_b?
    assert_not gs.solved_b?
  end

  test "update! persists across new find_or_create calls" do
    session = make_session
    gs = GuestGameSession.find_or_create(session, 5)
    gs.update!(attempts_c: 3)
    gs2 = GuestGameSession.find_or_create(session, 5)
    assert_equal 3, gs2.attempts_c
  end

  test "reload returns self" do
    session = make_session
    gs = GuestGameSession.find_or_create(session, 1)
    assert_same gs, gs.reload
  end

  test "hints default to 0 even when never set" do
    session = make_session
    gs = GuestGameSession.find_or_create(session, 99)
    assert_equal 0, gs.hints_a
    assert_equal 0, gs.hints_b
    assert_equal 0, gs.hints_c
  end
end
