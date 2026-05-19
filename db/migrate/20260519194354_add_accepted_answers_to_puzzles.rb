class AddAcceptedAnswersToPuzzles < ActiveRecord::Migration[8.1]
  def change
    add_column :puzzles, :accepted_answers_a, :string, array: true, default: []
    add_column :puzzles, :accepted_answers_b, :string, array: true, default: []
    add_column :puzzles, :accepted_answers_c, :string, array: true, default: []
  end
end
