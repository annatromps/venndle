class CreateFavourites < ActiveRecord::Migration[8.1]
  def change
    create_table :favourites do |t|
      t.references :user, null: false, foreign_key: true
      t.references :puzzle, null: false, foreign_key: true
      t.timestamps
    end
    add_index :favourites, [:user_id, :puzzle_id], unique: true
  end
end
