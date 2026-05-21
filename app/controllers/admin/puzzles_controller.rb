class Admin::PuzzlesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_puzzle, only: [:show, :edit, :update, :destroy]

  def index
    @scheduled     = Puzzle.where(puzzle_type: "daily").where.not(scheduled_date: nil)
                           .order(scheduled_date: :asc)
    @community     = Puzzle.where(puzzle_type: "user").where(scheduled_date: nil)
                           .includes(:user).order(created_at: :desc)
    @admin_created = Puzzle.where(puzzle_type: "admin")
                           .order(created_at: :desc)
  end

  def show
  end

  def new
    @puzzle = Puzzle.new(puzzle_type: "admin", published: false)
  end

  def create
    attrs = puzzle_params
    if attrs[:scheduled_date].present?
      attrs = attrs.merge(puzzle_type: "daily", published: true)
    else
      attrs = attrs.merge(puzzle_type: "admin", published: false)
    end
    @puzzle = Puzzle.new(attrs)
    @puzzle.user = current_user
    if @puzzle.save
      generate_accepted_answers_for(@puzzle)
      notice = @puzzle.puzzle_type == "daily" ? "Puzzle scheduled." : "Puzzle saved to your library."
      redirect_to admin_puzzles_path, notice: notice
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    attrs = puzzle_params
    if @puzzle.puzzle_type == "admin" && attrs[:scheduled_date].present?
      attrs = attrs.merge(puzzle_type: "daily", published: true)
    end
    if @puzzle.update(attrs)
      generate_accepted_answers_for(@puzzle)
      notice = @puzzle.puzzle_type == "daily" && @puzzle.scheduled_date? ? "Puzzle scheduled." : "Puzzle updated."
      redirect_to admin_puzzles_path, notice: notice
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @puzzle.destroy
    redirect_to admin_puzzles_path, notice: "Puzzle deleted."
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
