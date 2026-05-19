class GameSession < ApplicationRecord
  belongs_to :user
  belongs_to :puzzle

  def solved_all?
    solved_a? && solved_b? && solved_c?
  end

  def attempts_for(label)
    send("attempts_#{label}")
  end

  def solved_for?(label)
    send("solved_#{label}?")
  end
end
