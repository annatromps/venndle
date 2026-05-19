class Attempt < ApplicationRecord
  belongs_to :user
  belongs_to :puzzle

  validates :label, inclusion: { in: %w[a b c] }
  validates :guess, presence: true
end
