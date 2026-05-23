class PuzzleFeedback < ApplicationRecord
  belongs_to :puzzle
  belongs_to :user

  validates :body, presence: true
  validates :user_id, uniqueness: { scope: :puzzle_id }
end
