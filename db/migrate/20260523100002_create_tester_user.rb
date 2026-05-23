class CreateTesterUser < ActiveRecord::Migration[8.1]
  def up
    return if User.exists?(email: "tester@venndle.app")
    User.create!(
      email:    "tester@venndle.app",
      username: "tester",
      password: "Tester2026!",
      tester:   true
    )
  end

  def down
    User.find_by(email: "tester@venndle.app")&.destroy
  end
end
