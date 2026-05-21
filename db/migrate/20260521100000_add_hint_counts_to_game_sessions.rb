class AddHintCountsToGameSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :game_sessions, :hints_a, :integer, default: 0, null: false
    add_column :game_sessions, :hints_b, :integer, default: 0, null: false
    add_column :game_sessions, :hints_c, :integer, default: 0, null: false
  end
end
