class MakeAttemptsUserIdNullable < ActiveRecord::Migration[8.1]
  def change
    change_column_null :attempts, :user_id, true
  end
end
