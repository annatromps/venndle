require "test_helper"

class FavouritesControllerTest < ActionDispatch::IntegrationTest
  # ── authenticated ──────────────────────────────────────────────────────────────

  test "signed-in user can favourite a puzzle" do
    sign_in users(:alice)
    post puzzle_favourite_path(puzzles(:community_puzzle)), as: :json
    assert_response :success
    assert JSON.parse(response.body)["favourited"]
    assert Favourite.exists?(user: users(:alice), puzzle: puzzles(:community_puzzle))
  end

  test "favouriting twice does not create a duplicate" do
    sign_in users(:alice)
    puzzle = puzzles(:community_puzzle)
    post puzzle_favourite_path(puzzle), as: :json
    post puzzle_favourite_path(puzzle), as: :json
    assert_equal 1, Favourite.where(user: users(:alice), puzzle: puzzle).count
  end

  test "signed-in user can unfavourite a puzzle" do
    sign_in users(:alice)
    puzzle = puzzles(:community_puzzle)
    Favourite.create!(user: users(:alice), puzzle: puzzle)
    delete "/puzzles/#{puzzle.id}/favourite", as: :json
    assert_response :success
    assert_not JSON.parse(response.body)["favourited"]
    assert_not Favourite.exists?(user: users(:alice), puzzle: puzzle)
  end

  # ── guest ─────────────────────────────────────────────────────────────────────

  test "guest can favourite a puzzle via session" do
    puzzle = puzzles(:community_puzzle)
    post puzzle_favourite_path(puzzle), as: :json
    assert_response :success
    assert_includes session["guest_favourites"], puzzle.id
  end

  test "guest favouriting twice does not duplicate" do
    puzzle = puzzles(:community_puzzle)
    post puzzle_favourite_path(puzzle), as: :json
    post puzzle_favourite_path(puzzle), as: :json
    assert_equal 1, session["guest_favourites"].count(puzzle.id)
  end

  test "guest can unfavourite a puzzle" do
    puzzle = puzzles(:community_puzzle)
    post puzzle_favourite_path(puzzle), as: :json
    delete "/puzzles/#{puzzle.id}/favourite", as: :json
    assert_response :success
    assert_not_includes session["guest_favourites"] || [], puzzle.id
  end
end
