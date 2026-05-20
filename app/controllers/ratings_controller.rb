class RatingsController < ApplicationController
  before_action :authenticate_user!

  def create
    puzzle = Puzzle.find(params[:puzzle_id])
    score  = params[:score].to_i

    unless (1..5).include?(score)
      render json: { error: "Invalid score" }, status: :bad_request and return
    end

    rating = Rating.find_or_initialize_by(user: current_user, puzzle: puzzle)
    rating.score = score
    rating.save!

    render json: {
      score:   rating.score,
      average: puzzle.ratings.average(:score).to_f.round(1),
      count:   puzzle.ratings.count
    }
  end
end
