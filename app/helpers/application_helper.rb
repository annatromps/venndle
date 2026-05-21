module ApplicationHelper
  def build_share_string_for(game_session, puzzle)
    lines = %w[a b c].map do |label|
      attempts_count = game_session.send("attempts_#{label}")
      solved    = game_session.send("solved_#{label}?")
      gave_up   = game_session.respond_to?("gave_up_#{label}?")   && game_session.send("gave_up_#{label}?")
      hint_used = game_session.respond_to?("hint_used_#{label}?") && game_session.send("hint_used_#{label}?")
      wrong  = gave_up ? attempts_count : [attempts_count - (solved ? 1 : 0), 0].max
      result = gave_up ? "🏳️" : (solved ? (hint_used ? "💡" : "✅") : "")
      "#{label.upcase} #{("❌" * wrong)}#{result}"
    end
    url = "#{request.base_url}/puzzles/#{puzzle.id}"
    title = puzzle.title.present? ? puzzle.title : "Venndle ##{puzzle.id}"
    "#{title}\n#{lines.join("\n")}\n#{url}"
  end
end
