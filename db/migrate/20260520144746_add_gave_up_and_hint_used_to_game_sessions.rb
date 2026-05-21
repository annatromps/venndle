class AddGaveUpAndHintUsedToGameSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :game_sessions, :gave_up_a, :boolean, default: false, null: false
    add_column :game_sessions, :gave_up_b, :boolean, default: false, null: false
    add_column :game_sessions, :gave_up_c, :boolean, default: false, null: false
    add_column :game_sessions, :hint_used_a, :boolean, default: false, null: false
    add_column :game_sessions, :hint_used_b, :boolean, default: false, null: false
    add_column :game_sessions, :hint_used_c, :boolean, default: false, null: false
  end
end
