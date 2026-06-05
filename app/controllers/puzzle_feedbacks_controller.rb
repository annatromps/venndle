class PuzzleFeedbacksController < ApplicationController
  before_action :authenticate_user!

  def create
    puzzle = Puzzle.find(params[:puzzle_id])
    feedback = PuzzleFeedback.find_or_initialize_by(puzzle: puzzle, user: current_user)
    feedback.body            = params[:body].to_s.strip
    feedback.missing_answers = params[:missing_answers].to_s.strip.presence

    if feedback.body.blank?
      redirect_back fallback_location: root_path, alert: "Feedback can't be blank."
    elsif feedback.save
      redirect_back fallback_location: root_path, notice: "Feedback saved."
    else
      redirect_back fallback_location: root_path, alert: "Couldn't save feedback."
    end
  end
end
