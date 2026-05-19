class Admin::PuzzlesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_puzzle, only: [:show, :edit, :update, :destroy]

  def index
    @puzzles = Puzzle.includes(:user).order(created_at: :desc)
  end

  def show
  end

  def new
    @puzzle = Puzzle.new
  end

  def create
    @puzzle = Puzzle.new(puzzle_params)
    @puzzle.user = current_user
    if @puzzle.save
      redirect_to admin_puzzle_path(@puzzle), notice: "Puzzle created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @puzzle.update(puzzle_params)
      redirect_to admin_puzzle_path(@puzzle), notice: "Puzzle updated."
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
