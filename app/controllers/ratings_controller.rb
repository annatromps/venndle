class RatingsController < ApplicationController
  before_action :authenticate_user!

  def create
    puzzle = Puzzle.find(params[:puzzle_id])
    score  = params[:score].to_i

    unless score.between?(1, 5)
      render json: { error: "Invalid score" }, status: :unprocessable_entity and return
    end

    rating = Rating.find_or_initialize_by(puzzle: puzzle, user: current_user)
    rating.score = score
    rating.save!

    avg   = puzzle.ratings.average(:score).to_f.round(1)
    count = puzzle.ratings.count
    render json: { success: true, average: avg, count: count, your_score: score }
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
