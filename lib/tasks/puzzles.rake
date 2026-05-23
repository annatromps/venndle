namespace :puzzles do
  desc "Generate (or regenerate) accepted answers. FORCE=true regenerates all. DAILY_ONLY=true restricts to scheduled daily puzzles."
  task generate_accepted_answers: :environment do
    force       = ENV["FORCE"] == "true"
    daily_only  = ENV["DAILY_ONLY"] == "true"

    scope = Puzzle.published
    scope = scope.daily if daily_only

    puzzles = if force
      scope.order(:id)
    else
      scope.where(
        "array_length(accepted_answers_a, 1) IS NULL OR array_length(accepted_answers_a, 1) < 5 OR " \
        "array_length(accepted_answers_b, 1) IS NULL OR array_length(accepted_answers_b, 1) < 5 OR " \
        "array_length(accepted_answers_c, 1) IS NULL OR array_length(accepted_answers_c, 1) < 5"
      ).order(:id)
    end

    puts "Found #{puzzles.count} puzzle(s) to process (FORCE=#{force}, DAILY_ONLY=#{daily_only})."

    puzzles.each do |puzzle|
      puts "  Puzzle ##{puzzle.id} — #{puzzle.title.presence || '(no title)'}"
      %w[a b c].each do |lbl|
        answers = AcceptedAnswersService.call(puzzle.send("label_#{lbl}"), puzzle.all_circle_words_for(lbl))
        puzzle.update_column("accepted_answers_#{lbl}", answers)
        puts "    Circle #{lbl.upcase} (#{puzzle.send("label_#{lbl}")}): #{answers.count} answers — #{answers.first(5).join(', ')}..."
        sleep 1
      end
    rescue => e
      puts "    ERROR for puzzle ##{puzzle.id}: #{e.message}"
    end

    puts "Done."
  end
end
