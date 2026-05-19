module ApplicationHelper
  def build_share_string_for(game_session, puzzle)
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
