class Admin::PuzzlesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_puzzle, only: [:show, :edit, :update, :destroy, :schedule, :unschedule]

  def index
    @scheduled   = Puzzle.where(puzzle_type: "daily").where.not(scheduled_date: nil)
                         .order(scheduled_date: :asc)
    @unscheduled = Puzzle.where(puzzle_type: "user").where(scheduled_date: nil)
                         .includes(:user).order(created_at: :desc)
  end

  def show
  end

  def new
    @puzzle = Puzzle.new(puzzle_type: "daily", published: true)
    if params[:from_import].present?
      @puzzle.title     = params[:title].presence
      @puzzle.label_a   = params[:label_a].presence
      @puzzle.label_b   = params[:label_b].presence
      @puzzle.label_c   = params[:label_c].presence
      @puzzle.words_a   = params[:words_a].to_s.split(",").map(&:strip).reject(&:blank?)
      @puzzle.words_b   = params[:words_b].to_s.split(",").map(&:strip).reject(&:blank?)
      @puzzle.words_c   = params[:words_c].to_s.split(",").map(&:strip).reject(&:blank?)
      @puzzle.words_ab  = params[:words_ab].to_s.split(",").map(&:strip).reject(&:blank?)
      @puzzle.words_ac  = params[:words_ac].to_s.split(",").map(&:strip).reject(&:blank?)
      @puzzle.words_bc  = params[:words_bc].to_s.split(",").map(&:strip).reject(&:blank?)
      @puzzle.words_abc = params[:words_abc].to_s.split(",").map(&:strip).reject(&:blank?)
    end
  end

  def create
    @puzzle = Puzzle.new(puzzle_params)
    @puzzle.user = current_user
    if @puzzle.save
      generate_accepted_answers_for(@puzzle)
      redirect_to admin_puzzles_path, notice: "Puzzle scheduled."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @puzzle.update(puzzle_params)
      generate_accepted_answers_for(@puzzle)
      redirect_to admin_puzzle_path(@puzzle), notice: "Puzzle updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def unschedule
    @puzzle.update!(puzzle_type: "user", scheduled_date: nil)
    redirect_to admin_puzzles_path, notice: "Puzzle removed from schedule."
  end

  def destroy
    @puzzle.destroy
    redirect_to admin_puzzles_path, notice: "Puzzle deleted."
  end

  def schedule
    date = Date.parse(params[:scheduled_date])
    @puzzle.update!(scheduled_date: date, puzzle_type: "daily", published: true)
    redirect_to admin_puzzles_path, notice: "Puzzle scheduled for #{date.strftime("%-d %b %Y")}."
  rescue ArgumentError
    redirect_to admin_puzzles_path, alert: "Invalid date."
  end

  private

  def set_puzzle
    @puzzle = Puzzle.find(params[:id])
  end

  def require_admin
    redirect_to root_path, alert: "Not authorised." unless current_user.admin?
  end

  def puzzle_params
    permitted = params.require(:puzzle).permit(
      :title, :puzzle_type, :scheduled_date, :published,
      :label_a, :label_b, :label_c,
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
end
