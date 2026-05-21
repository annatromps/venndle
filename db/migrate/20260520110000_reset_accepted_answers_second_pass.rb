class ResetAcceptedAnswersSecondPass < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE puzzles SET accepted_answers_a = '{}', accepted_answers_b = '{}', accepted_answers_c = '{}'"
  end

  def down
  end
end
