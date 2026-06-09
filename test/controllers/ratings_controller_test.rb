require "test_helper"

class RatingsControllerTest < ActionDispatch::IntegrationTest
  test "guest cannot submit a rating" do
    post puzzle_rating_path(puzzles(:community_puzzle)), params: { score: 4 }, as: :json
    assert_response :unauthorized
  end

  test "valid score is saved and returns success" do
    sign_in users(:alice)
    post puzzle_rating_path(puzzles(:community_puzzle)), params: { score: 4 }, as: :json
    assert_response :success
    data = JSON.parse(response.body)
    assert data["success"]
    assert_equal 4, data["your_score"]
  end

  test "score below 1 is rejected" do
    sign_in users(:alice)
    post puzzle_rating_path(puzzles(:community_puzzle)), params: { score: 0 }, as: :json
    assert_response :unprocessable_entity
  end

  test "score above 5 is rejected" do
    sign_in users(:alice)
    post puzzle_rating_path(puzzles(:community_puzzle)), params: { score: 6 }, as: :json
    assert_response :unprocessable_entity
  end

  test "submitting twice updates existing rating" do
    sign_in users(:alice)
    puzzle = puzzles(:community_puzzle)
    post puzzle_rating_path(puzzle), params: { score: 3 }, as: :json
    post puzzle_rating_path(puzzle), params: { score: 5 }, as: :json
    assert_equal 1, Rating.where(puzzle: puzzle, user: users(:alice)).count
    assert_equal 5, Rating.find_by(puzzle: puzzle, user: users(:alice)).score
  end

  test "response includes updated average and count" do
    sign_in users(:alice)
    sign_in users(:bob)
    post puzzle_rating_path(puzzles(:community_puzzle)), params: { score: 4 }, as: :json
    data = JSON.parse(response.body)
    assert data["average"]
    assert data["count"]
  end
end
