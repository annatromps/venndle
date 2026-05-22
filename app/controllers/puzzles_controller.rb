class PuzzlesController < ApplicationController
  before_action :require_login_to_create, only: [:new, :create]

  def daily
    all_daily = Puzzle.published.daily.where("scheduled_date <= ?", Date.today).order(scheduled_date: :asc)

    if params[:day_number].present?
      @day_number = params[:day_number].to_i
      @puzzle = all_daily.offset(@day_number - 1).first
      if @puzzle
        @game_session = find_or_build_game_session(@puzzle)
        @attempts = load_attempts(@puzzle)
      end
    else
      current_day = all_daily.count
      if current_day > 0
        redirect_to daily_puzzle_path(current_day) and return
      end
      @puzzle = nil
    end
  end

  def index
    @filter = params[:filter].presence || "all"

    @played_ids = if user_signed_in?
      current_user.game_sessions.where(completed: true).pluck(:puzzle_id).to_set
    else
      (session["guest_game_sessions"] || {})
        .select { |_, d| d["completed"] }
        .keys.map(&:to_i).to_set
    end

    @favourite_ids = if user_signed_in?
      current_user.favourites.pluck(:puzzle_id).to_set
    else
      (session["guest_favourites"] || []).to_set
    end

    @puzzles = Puzzle.published.includes(:user).order(created_at: :desc)
    case @filter
    when "played"
      @puzzles = @puzzles.where(id: @played_ids.to_a)
    when "my"
      @puzzles = user_signed_in? ? @puzzles.where(user: current_user) : Puzzle.none
    when "favourites"
      @puzzles = @puzzles.where(id: @favourite_ids.to_a)
    end

    @play_counts = GameSession.where(puzzle_id: @puzzles.map(&:id)).group(:puzzle_id).count
  end

  def archive
    @puzzles = Puzzle.published.daily.where("scheduled_date <= ?", Date.today).order(scheduled_date: :desc).to_a
    total = @puzzles.size
    @day_numbers = {}
    @puzzles.each_with_index { |p, i| @day_numbers[p.id] = total - i }
    puzzle_ids = @puzzles.map(&:id)
    played_ids = if user_signed_in?
      current_user.game_sessions.where(puzzle_id: puzzle_ids).pluck(:puzzle_id)
    else
      (session["guest_game_sessions"] || {}).keys.map(&:to_i)
    end
    @played_ids = played_ids.to_set
  end

  def show
    @puzzle = Puzzle.find(params[:id])
    @game_session = find_or_build_game_session(@puzzle)
    @attempts = load_attempts(@puzzle)
  end

  def new
    @puzzle = Puzzle.new
  end

  def create
    @puzzle = Puzzle.new(puzzle_params)
    @puzzle.user = current_user
    @puzzle.puzzle_type = "user"

    if @puzzle.title.blank?
      @puzzle.title = "#{Date.today.strftime("%-d %b")} · ##{(Puzzle.count + 1).to_s.rjust(3, "0")}"
    end

    if @puzzle.save
      generate_accepted_answers_for(@puzzle)
      flash[:just_created] = @puzzle.id
      redirect_to @puzzle
    else
      render :new, status: :unprocessable_entity
    end
  end

  def guess
    @puzzle = Puzzle.find(params[:id])
    label = params[:label].to_s.downcase
    guess = params[:guess].to_s.strip

    unless %w[a b c].include?(label)
      render json: { error: "Invalid label" }, status: :bad_request and return
    end

    if guess.blank?
      render json: { error: "Guess cannot be blank" }, status: :bad_request and return
    end

    game_session = find_or_build_game_session(@puzzle)
    normalized_guess = guess.downcase

    if duplicate_guess?(label, normalized_guess)
      render json: { duplicate: true } and return
    end

    correct_label = @puzzle.send("label_#{label}")
    raw_accepted = @puzzle.send("accepted_answers_#{label}") || []
    accepted = raw_accepted.map { |a| a.to_s.downcase.strip }

    Rails.logger.info "=== GUESS DEBUG ==="
    Rails.logger.info "Guess: #{normalized_guess}"
    Rails.logger.info "Label #{label}: #{correct_label}"
    Rails.logger.info "Accepted answers (#{accepted.size}): #{accepted.first(6).inspect}"
    Rails.logger.info "Match result: #{accepted.include?(normalized_guess)}"

    if accepted.include?(normalized_guess)
      correct = true
    else
      circle_words = @puzzle.all_circle_words_for(label)
      correct = AnthropicJudgeService.call(guess, correct_label, circle_words)
      if correct
        @puzzle.update_column("accepted_answers_#{label}", (accepted + [normalized_guess]).uniq)
      end
    end

    if user_signed_in?
      Attempt.create!(user: current_user, puzzle: @puzzle, label: label, guess: guess, correct: correct)
    else
      save_guest_attempt(@puzzle, label, guess, correct)
    end

    game_session.increment!("attempts_#{label}")
    game_session.update!("solved_#{label}" => true) if correct
    game_session.reload
    game_session.update!(completed: true) if game_session.solved_a? && game_session.solved_b? && game_session.solved_c?

    share_string = build_share_string(game_session, @puzzle)

    render json: {
      correct: correct,
      official_label: correct_label,
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
  rescue => e
    Rails.logger.error "Guess action error: #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    render json: { error: "Something went wrong: #{e.message}" }, status: :internal_server_error
  end

  private

  def require_login_to_create
    unless user_signed_in?
      redirect_to new_user_session_path, alert: "Sign in to create your own Venndle puzzle."
    end
  end

  def find_or_build_game_session(puzzle)
    if user_signed_in?
      GameSession.find_or_create_by(user: current_user, puzzle: puzzle)
    else
      GuestGameSession.find_or_create(session, puzzle.id)
    end
  end

  def load_attempts(puzzle)
    if user_signed_in?
      current_user.attempts.where(puzzle: puzzle).order(:created_at)
    else
      key = "guest_attempts_#{puzzle.id}"
      (session[key] || []).map do |a|
        GuestAttempt.new(label: a["label"], guess: a["guess"], correct: a["correct"])
      end
    end
  end

  def duplicate_guess?(label, normalized_guess)
    if user_signed_in?
      current_user.attempts
        .where(puzzle: @puzzle, label: label)
        .any? { |a| a.guess.to_s.downcase.strip == normalized_guess }
    else
      key = "guest_attempts_#{@puzzle.id}"
      (session[key] || []).any? { |a| a["label"] == label && a["guess"].to_s.downcase.strip == normalized_guess }
    end
  end

  def save_guest_attempt(puzzle, label, guess, correct)
    key = "guest_attempts_#{puzzle.id}"
    attempts = (session[key] || []).dup
    attempts << { "label" => label, "guess" => guess, "correct" => correct }
    session[key] = attempts
  end

  def puzzle_params
    permitted = params.require(:puzzle).permit(
      :title, :published, :label_a, :label_b, :label_c,
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
    lines = %w[a b c].map do |label|
      attempts_count = game_session.send("attempts_#{label}")
      solved = game_session.send("solved_#{label}?")
      wrong = [attempts_count - (solved ? 1 : 0), 0].max
      emojis = ("❌" * wrong) + (solved ? "✅" : "")
      "#{label.upcase} #{emojis}"
    end
    if puzzle.puzzle_type == "daily"
      url = "#{request.base_url}/daily/#{puzzle.day_number}"
    else
      url = "#{request.base_url}/puzzles/#{puzzle.id}"
    end
    title = puzzle.title.present? ? puzzle.title : "Venndle ##{puzzle.id}"
    "#{title}\n#{lines.join("\n")}\n#{url}"
  end
end
