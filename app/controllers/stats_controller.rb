class StatsController < ApplicationController
  before_action :authenticate_user!

  def show
    sessions = current_user.game_sessions
      .joins(:puzzle)
      .where(puzzles: { puzzle_type: "daily" })
      .where("puzzles.scheduled_date <= ?", Date.today)
      .includes(:puzzle)
      .to_a

    completed = sessions.select(&:completed?)

    played_dates = completed.map { |gs| gs.puzzle.scheduled_date }.to_set
    @current_streak = streak_from(played_dates, start: Date.today)
    @longest_streak = longest_streak(played_dates)
    @total_completed = completed.size

    misses = completed.map do |gs|
      wrong_a = gs.attempts_a - (gs.gave_up_a? ? 0 : 1)
      wrong_b = gs.attempts_b - (gs.gave_up_b? ? 0 : 1)
      wrong_c = gs.attempts_c - (gs.gave_up_c? ? 0 : 1)
      wrong_a + wrong_b + wrong_c
    end

    @avg_misses  = misses.empty? ? nil : (misses.sum.to_f / misses.size).round(1)
    @best_misses = misses.empty? ? nil : misses.min

    dist = Hash.new(0)
    misses.each { |m| dist[m > 3 ? "3+" : m.to_s] += 1 }
    @score_distribution = [["0", dist["0"]], ["1", dist["1"]], ["2", dist["2"]], ["3+", dist["3+"]]]
  end

  private

  def streak_from(played_dates, start:)
    date = played_dates.include?(start) ? start : start - 1
    count = 0
    while played_dates.include?(date)
      count += 1
      date -= 1
    end
    count
  end

  def longest_streak(played_dates)
    return 0 if played_dates.empty?
    dates = played_dates.sort
    max = cur = 1
    dates.each_cons(2) do |a, b|
      cur = (b - a == 1) ? cur + 1 : 1
      max = cur if cur > max
    end
    max
  end
end
