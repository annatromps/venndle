namespace :puzzles do
  desc "Generate accepted answers for puzzles that don't have them yet"
  task generate_accepted_answers: :environment do
    puzzles = Puzzle.where("accepted_answers_a = '{}' OR accepted_answers_b = '{}' OR accepted_answers_c = '{}'")
    puts "Found #{puzzles.count} puzzle(s) needing accepted answers."

    puzzles.each do |puzzle|
      puts "  Puzzle ##{puzzle.id} — #{puzzle.title.presence || '(no title)'}"
      %w[a b c].each do |lbl|
        next if puzzle.send("accepted_answers_#{lbl}").present?
        answers = AcceptedAnswersService.call(puzzle.send("label_#{lbl}"), puzzle.all_circle_words_for(lbl))
        puzzle.update_column("accepted_answers_#{lbl}", answers)
        puts "    Circle #{lbl.upcase}: #{answers.count} answers (#{answers.first(4).join(', ')}...)"
      end
    rescue => e
      puts "    ERROR: #{e.message}"
    end

    puts "Done."
  end
end
