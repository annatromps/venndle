namespace :puzzles do
  desc "Generate (or regenerate) accepted answers for puzzles that are missing them or have thin lists"
  task generate_accepted_answers: :environment do
    # Catch empty arrays AND thin lists (< 5 entries = likely just the fallback label from a failed API call)
    puzzles = Puzzle.where(
      "array_length(accepted_answers_a, 1) IS NULL OR array_length(accepted_answers_a, 1) < 5 OR " \
      "array_length(accepted_answers_b, 1) IS NULL OR array_length(accepted_answers_b, 1) < 5 OR " \
      "array_length(accepted_answers_c, 1) IS NULL OR array_length(accepted_answers_c, 1) < 5"
    )
    puts "Found #{puzzles.count} puzzle(s) needing accepted answers."

    puzzles.each do |puzzle|
      puts "  Puzzle ##{puzzle.id} — #{puzzle.title.presence || '(no title)'}"
      %w[a b c].each do |lbl|
        existing = puzzle.send("accepted_answers_#{lbl}")
        next if existing.present? && existing.length >= 5
        answers = AcceptedAnswersService.call(puzzle.send("label_#{lbl}"), puzzle.all_circle_words_for(lbl))
        puzzle.update_column("accepted_answers_#{lbl}", answers)
        puts "    Circle #{lbl.upcase} (#{puzzle.send("label_#{lbl}")}): #{answers.count} answers — #{answers.first(5).join(', ')}..."
      end
    rescue => e
      puts "    ERROR: #{e.message}"
    end

    puts "Done."
  end
end
