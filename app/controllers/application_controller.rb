class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :detect_social_crawler

  helper_method :admin_view?
  def admin_view?
    user_signed_in? && current_user.admin? && session.fetch(:admin_view, true)
  end

  def toggle_admin_view
    session[:admin_view] = !session.fetch(:admin_view, true)
    redirect_back fallback_location: root_path
  end

  def detect_social_crawler
    @suppress_og = request.user_agent.to_s.match?(/facebookexternalhit|WhatsApp/i)
  end

  private

  def generate_accepted_answers_for(puzzle)
    return if ENV["GEMINI_API_KEY"].blank?
    all_puzzle_words = puzzle.all_words.map { |w| w.to_s.downcase.strip }
    %w[a b c].each do |lbl|
      answers = AcceptedAnswersService.call(puzzle.send("label_#{lbl}"), puzzle.all_circle_words_for(lbl), all_puzzle_words)
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
