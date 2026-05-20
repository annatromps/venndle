class Rating < ApplicationRecord
  belongs_to :user
  belongs_to :puzzle

  validates :score, inclusion: { in: 1..5 }
  validates :user_id, uniqueness: { scope: :puzzle_id }
end
