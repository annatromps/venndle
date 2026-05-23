class CreatePuzzleFeedbacks < ActiveRecord::Migration[8.1]
  def change
    create_table :puzzle_feedbacks do |t|
      t.references :puzzle, null: false, foreign_key: true
      t.references :user,   null: false, foreign_key: true
      t.text :body, null: false
      t.timestamps
    end
    add_index :puzzle_feedbacks, [:user_id, :puzzle_id], unique: true
  end
end
