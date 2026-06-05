class AddHardModeTesterToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :hard_mode_tester, :boolean, default: false, null: false
  end
end
