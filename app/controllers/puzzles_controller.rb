class PuzzlesController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create]

  def daily
    @puzzle = Puzzle.published.daily.where(scheduled_date: Date.today).first ||
              Puzzle.published.daily.order(scheduled_date: :desc).first

    if @puzzle && user_signed_in?
      @game_session = GameSession.find_or_create_by(user: current_user, puzzle: @puzzle)
      @attempts = current_user.attempts.where(puzzle: @puzzle).order(:created_at)
    end
  end

  def index
    @puzzles = Puzzle.published.includes(:user).order(created_at: :desc)
  end

  def show
    @puzzle = Puzzle.find(params[:id])
    if user_signed_in?
      @game_session = GameSession.find_or_create_by(user: current_user, puzzle: @puzzle)
      @attempts = current_user.attempts.where(puzzle: @puzzle).order(:created_at)
    end
  end

  def new
    @puzzle = Puzzle.new
  end

  def create
    @puzzle = Puzzle.new(puzzle_params)
    @puzzle.user = current_user
    @puzzle.puzzle_type = "user"
    @puzzle.published = true

    if @puzzle.save
      redirect_to @puzzle, notice: "Puzzle created!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def guess
    unless user_signed_in?
      render json: { error: "Login required" }, status: :unauthorized and return
    end

    @puzzle = Puzzle.find(params[:id])
    label = params[:label].to_s.downcase
    guess = params[:guess].to_s.strip

    unless %w[a b c].include?(label)
      render json: { error: "Invalid label" }, status: :bad_request and return
    end

    game_session = GameSession.find_or_create_by(user: current_user, puzzle: @puzzle)

    correct_label = @puzzle.send("label_#{label}")
    circle_words = @puzzle.send("words_#{label}") || []

    correct = AnthropicJudgeService.call(guess, correct_label, circle_words)

    attempt = Attempt.create!(
      user: current_user,
      puzzle: @puzzle,
      label: label,
      guess: guess,
      correct: correct
    )

    game_session.increment!("attempts_#{label}")

    if correct
      game_session.update!("solved_#{label}" => true)
    end

    game_session.reload
    if game_session.solved_a? && game_session.solved_b? && game_session.solved_c?
      game_session.update!(completed: true)
    end

    share_string = build_share_string(game_session, @puzzle)

    render json: {
      correct: correct,
      solved: {
        a: game_session.solved_a?,
        b: game_session.solved_b?,
        c: game_session.solved_c?
      },
      completed: game_session.completed?,
      share_string: share_string,
      label_a: game_session.solved_a? ? @puzzle.label_a : nil,
      label_b: game_session.solved_b? ? @puzzle.label_b : nil,
      label_c: game_session.solved_c? ? @puzzle.label_c : nil
    }
  end

  private

  def puzzle_params
    permitted = params.require(:puzzle).permit(
      :title, :label_a, :label_b, :label_c,
      words_a: [], words_b: [], words_c: [],
      words_ab: [], words_ac: [], words_bc: [], words_abc: []
    )
    %w[words_a words_b words_c words_ab words_ac words_bc words_abc].each do |field|
      if permitted[field].present?
        permitted[field] = permitted[field].flat_map { |w| w.split(",") }.map(&:strip).reject(&:blank?)
      end
    end
    permitted
  end

  def build_share_string(game_session, puzzle)
    %w[a b c].map do |label|
      attempts_count = game_session.send("attempts_#{label}")
      solved = game_session.send("solved_#{label}?")
      wrong = [attempts_count - (solved ? 1 : 0), 0].max
      emojis = ("❌" * wrong) + (solved ? "✅" : "")
      circle_label = puzzle.send("label_#{label}")
      "#{circle_label}: #{emojis}"
    end.join(" | ")
  end
end
