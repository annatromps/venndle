class CreatePuzzles < ActiveRecord::Migration[8.1]
  def change
    create_table :puzzles do |t|
      t.string :title
      t.string :puzzle_type
      t.date :scheduled_date
      t.references :user, null: false, foreign_key: true
      t.string :label_a
      t.string :label_b
      t.string :label_c
      t.string :words_a, array: true, default: []
      t.string :words_b, array: true, default: []
      t.string :words_c, array: true, default: []
      t.string :words_ab, array: true, default: []
      t.string :words_ac, array: true, default: []
      t.string :words_bc, array: true, default: []
      t.string :words_abc, array: true, default: []
      t.boolean :published, default: false

      t.timestamps
    end
  end
end
