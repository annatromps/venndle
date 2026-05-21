class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :detect_social_crawler

  def detect_social_crawler
    @suppress_og = request.user_agent.to_s.match?(/facebookexternalhit|WhatsApp/i)
  end

  private

  def generate_accepted_answers_for(puzzle)
    return if ENV["GEMINI_API_KEY"].blank?
    %w[a b c].each do |lbl|
      answers = AcceptedAnswersService.call(puzzle.send("label_#{lbl}"), puzzle.all_circle_words_for(lbl))
      puzzle.update_column("accepted_answers_#{lbl}", answers)
      Rails.logger.info "Puzzle ##{puzzle.id} [#{lbl}=#{puzzle.send("label_#{lbl}")}]: stored #{answers.count} accepted answers"
    end
  rescue => e
    Rails.logger.error "AcceptedAnswers generation failed for puzzle #{puzzle.id}: #{e.message}"
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username])
  end
end
