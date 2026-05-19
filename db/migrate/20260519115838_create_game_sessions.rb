class CreateGameSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :game_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :puzzle, null: false, foreign_key: true
      t.boolean :completed, default: false
      t.integer :attempts_a, default: 0
      t.integer :attempts_b, default: 0
      t.integer :attempts_c, default: 0
      t.boolean :solved_a, default: false
      t.boolean :solved_b, default: false
      t.boolean :solved_c, default: false

      t.timestamps
    end
  end
end
