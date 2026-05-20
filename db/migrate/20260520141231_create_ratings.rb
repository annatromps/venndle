class CreateRatings < ActiveRecord::Migration[8.1]
  def change
    create_table :ratings do |t|
      t.references :puzzle, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :score, null: false
      t.timestamps
    end
    add_index :ratings, [:user_id, :puzzle_id], unique: true
  end
end
