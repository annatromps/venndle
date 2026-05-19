class SetAdminForAnna < ActiveRecord::Migration[8.1]
  def up
    User.find_by(email: "annamtrompetas@gmail.com")&.update_columns(admin: true)
  end

  def down
    User.find_by(email: "annamtrompetas@gmail.com")&.update_columns(admin: false)
  end
end
