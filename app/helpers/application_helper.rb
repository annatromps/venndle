module ApplicationHelper
  def build_share_string_for(game_session, puzzle)
    lines = %w[a b c].map do |label|
      attempts_count = game_session.send("attempts_#{label}")
      solved = game_session.send("solved_#{label}?")
      wrong = [attempts_count - (solved ? 1 : 0), 0].max
      emojis = ("❌" * wrong) + (solved ? "✅" : "")
      "#{label.upcase} #{emojis}"
    end
    url = "#{request.base_url}/puzzles/#{puzzle.id}"
    title = puzzle.title.present? ? puzzle.title : "Venndle ##{puzzle.id}"
    "#{title}\n#{lines.join("\n")}\n#{url}"
  end
end
