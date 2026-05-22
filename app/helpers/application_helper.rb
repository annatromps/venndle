module ApplicationHelper
  def game_id_for(puzzle)
    if puzzle.puzzle_type == "daily" && puzzle.scheduled_date.present?
      if puzzle.scheduled_date >= Date.today
        "daily_#{puzzle.scheduled_date.strftime('%Y-%m-%d')}"
      else
        day_num = Puzzle.published.daily.where("scheduled_date <= ?", puzzle.scheduled_date).count
        "archive_#{day_num}"
      end
    else
      "community_user#{puzzle.id}"
    end
  end

  def build_share_string_for(game_session, puzzle)
    lines = %w[a b c].map do |label|
      attempts_count = game_session.send("attempts_#{label}")
      solved  = game_session.send("solved_#{label}?")
      gave_up = game_session.respond_to?("gave_up_#{label}?") && game_session.send("gave_up_#{label}?")
      hints   = game_session.respond_to?("hints_#{label}") ? game_session.send("hints_#{label}").to_i : 0
      wrong    = gave_up ? attempts_count : [attempts_count - (solved ? 1 : 0), 0].max
      result   = gave_up ? "🏳️" : (solved ? "✅" : "")
      hint_str = hints > 0 ? ("💡" * hints) : ""
      "#{label.upcase} #{("❌" * wrong)}#{hint_str}#{result}"
    end
    if puzzle.puzzle_type == "daily" && puzzle.scheduled_date.present?
      day_num = Puzzle.published.daily.where("scheduled_date <= ?", puzzle.scheduled_date).count
      url   = "https://venndle.app/daily#{day_num}"
      title = "Venndle Daily — #{puzzle.scheduled_date.strftime("%-d %b %Y")}"
    else
      url   = "https://venndle.app/#{puzzle.id}"
      title = puzzle.title.presence || "Venndle ##{puzzle.id}"
    end
    "#{title}\n#{lines.join("\n")}\n#{url}"
  end
end
