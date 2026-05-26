class AddMissingAnswersToPuzzleFeedbacks < ActiveRecord::Migration[8.1]
  def change
    add_column :puzzle_feedbacks, :missing_answers, :text
  end
end
