class AddTesterToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :tester, :boolean, default: false, null: false
  end
end
