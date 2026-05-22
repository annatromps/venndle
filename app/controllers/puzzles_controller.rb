class PuzzlesController < ApplicationController
  before_action :require_login_to_create, only: [:new, :create]

  def daily
    all_daily = Puzzle.published.daily.where("scheduled_date <= ?", Date.today).order(scheduled_date: :asc)
    current_day = all_daily.count
    return redirect_to "/daily#{current_day}" if current_day > 0
    @puzzle = nil
  end

  def index
    @filter = params[:filter].presence || "all"
    @sort   = params[:sort].presence_in(%w[newest oldest top_rated lowest_rated popular]) || "newest"

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

    case @filter
    when "my"
      @puzzles = user_signed_in? ? Puzzle.where(user: current_user).includes(:user).order(created_at: :desc) : Puzzle.none
    when "played"
      @puzzles = Puzzle.published.user_created.where(id: @played_ids.to_a).includes(:user).order(created_at: :desc)
    when "favourites"
      @puzzles = Puzzle.published.user_created.where(id: @favourite_ids.to_a).includes(:user).order(created_at: :desc)
    else
      base = Puzzle.published.user_created.includes(:user)
      @puzzles = @sort == "oldest" ? base.order(created_at: :asc) : base.order(created_at: :desc)
    end

    @puzzles = @puzzles.to_a

    puzzle_ids = @puzzles.map(&:id)
    @play_counts    = GameSession.where(puzzle_id: puzzle_ids).group(:puzzle_id).count
    @rating_averages = Rating.where(puzzle_id: puzzle_ids).group(:puzzle_id).average(:score)
                             .transform_values { |v| v.to_f.round(1) }
    @avg_ratings    = @rating_averages
    @rating_counts  = Rating.where(puzzle_id: puzzle_ids).group(:puzzle_id).count

    case @sort
    when "popular"
      @puzzles = @puzzles.sort_by { |p| -(@play_counts[p.id] || 0) }
    when "top_rated"
      @puzzles = @puzzles.sort_by { |p| [-(@rating_averages[p.id] || 0), -p.id] }
    when "lowest_rated"
      @puzzles = @puzzles.sort_by { |p| [(@rating_averages[p.id] ? @rating_averages[p.id] : Float::INFINITY), -p.id] }
    end
  end

  def archive
    scope = Puzzle.published.daily
    scope = user_signed_in? && current_user.admin? ? scope : scope.where("scheduled_date <= ?", Date.today)
    @puzzles = scope.order(scheduled_date: :desc).to_a

    past = @puzzles.select { |p| p.scheduled_date <= Date.today }.sort_by(&:scheduled_date)
    @day_numbers = {}
    past.each_with_index { |p, i| @day_numbers[p.id] = i + 1 }

    if user_signed_in?
      game_sessions = current_user.game_sessions.where(completed: true, puzzle_id: @puzzles.map(&:id))
      @played_ids = game_sessions.pluck(:puzzle_id).to_set
      @game_sessions_by_puzzle_id = game_sessions.index_by(&:puzzle_id)
    else
      guest_sessions = (session["guest_game_sessions"] || {}).select { |_, d| d["completed"] }
      @played_ids = guest_sessions.keys.map(&:to_i).to_set
      @game_sessions_by_puzzle_id = {}
      @played_ids.each do |pid|
        @game_sessions_by_puzzle_id[pid] = GuestGameSession.find_or_create(session, pid)
      end
    end
  end

  def show
    @puzzle = Puzzle.find(params[:id])
    @game_session = find_or_build_game_session(@puzzle)
    @attempts = load_attempts(@puzzle)
  end

  def show_by_daily_number
    number = params[:number].to_i
    @puzzle = Puzzle.published.daily.order(:scheduled_date).offset(number - 1).limit(1).first
    if @puzzle.nil?
      redirect_to archive_path, alert: "Daily ##{number} not found." and return
    end
    unless @puzzle.scheduled_date <= Date.today || (user_signed_in? && current_user.admin?)
      redirect_to archive_path, alert: "That puzzle isn't available yet." and return
    end
    @game_session = find_or_build_game_session(@puzzle)
    @attempts = load_attempts(@puzzle)
    render :show
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

  def hint
    @puzzle = Puzzle.find(params[:id])
    label = params[:label].to_s.downcase
    revealed_count = params[:revealed_count].to_i

    return render json: { error: "Invalid label" }, status: :bad_request unless %w[a b c].include?(label)

    official_label = @puzzle.send("label_#{label}").to_s
    return render json: { done: true } if revealed_count >= official_label.length

    game_session = find_or_build_game_session(@puzzle)
    game_session.update!("hint_used_#{label}" => true) unless game_session.send("hint_used_#{label}?")
    game_session.increment!("hints_#{label}")

    render json: {
      letter: official_label[revealed_count],
      total_length: official_label.length,
      position: revealed_count
    }
  end

  def give_up
    @puzzle = Puzzle.find(params[:id])
    label = params[:label].to_s.downcase

    return render json: { error: "Invalid label" }, status: :bad_request unless %w[a b c].include?(label)

    game_session = find_or_build_game_session(@puzzle)
    return render json: { already_solved: true } if game_session.send("solved_#{label}?")

    game_session.update!("solved_#{label}" => true, "gave_up_#{label}" => true)
    game_session.reload
    game_session.update!(completed: true) if game_session.solved_a? && game_session.solved_b? && game_session.solved_c?

    render json: {
      official_label: @puzzle.send("label_#{label}"),
      completed: game_session.completed?
    }
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
      solved   = game_session.send("solved_#{label}?")
      gave_up  = game_session.respond_to?("gave_up_#{label}?") && game_session.send("gave_up_#{label}?")
      hints    = game_session.respond_to?("hints_#{label}") ? game_session.send("hints_#{label}").to_i : 0
      wrong    = gave_up ? attempts_count : [attempts_count - (solved ? 1 : 0), 0].max
      result   = gave_up ? "🏳️" : (solved ? "✅" : "")
      hint_str = hints > 0 ? ("💡" * hints) : ""
      "#{label.upcase} #{("❌" * wrong)}#{hint_str}#{result}"
    end
    if puzzle.puzzle_type == "daily" && puzzle.scheduled_date.present?
      day_num = Puzzle.published.daily.where("scheduled_date <= ?", puzzle.scheduled_date).count
      url   = "venndle.app/daily#{day_num}"
      title = "Venndle Daily — #{puzzle.scheduled_date.strftime("%-d %b %Y")}"
    else
      url   = "venndle.app/#{puzzle.id}"
      title = puzzle.title.presence || "Venndle ##{puzzle.id}"
    end
    "#{title}\n#{lines.join("\n")}\n#{url}"
  end
end
