class Rating < ApplicationRecord
  belongs_to :puzzle
  belongs_to :user

  validates :score, inclusion: { in: 1..5 }
  validates :user_id, uniqueness: { scope: :puzzle_id }
end
