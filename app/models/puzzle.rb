class Puzzle < ApplicationRecord
  belongs_to :user
  has_many :attempts, dependent: :destroy
  has_many :game_sessions, dependent: :destroy

  validates :title, presence: true
  validates :puzzle_type, inclusion: { in: %w[daily user] }
  validates :label_a, :label_b, :label_c, presence: true

  scope :published, -> { where(published: true) }
  scope :daily, -> { where(puzzle_type: "daily") }
  scope :user_created, -> { where(puzzle_type: "user") }

  def all_words
    (words_a + words_b + words_c + words_ab + words_ac + words_bc + words_abc).uniq
  end

  def words_for_region(region)
    send("words_#{region}") || []
  end
end
