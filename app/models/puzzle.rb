class Puzzle < ApplicationRecord
  belongs_to :user
  has_many :attempts, dependent: :destroy
  has_many :game_sessions, dependent: :destroy
  has_many :favourites, dependent: :destroy

  validates :puzzle_type, inclusion: { in: %w[daily user admin] }
  validates :label_a, :label_b, :label_c, presence: true

  scope :published, -> { where(published: true) }
  scope :daily, -> { where(puzzle_type: "daily") }
  scope :user_created, -> { where(puzzle_type: "user") }
  scope :admin_created, -> { where(puzzle_type: "admin") }

  def all_words
    (words_a + words_b + words_c + words_ab + words_ac + words_bc + words_abc).uniq
  end

  def words_for_region(region)
    send("words_#{region}") || []
  end

  def all_circle_words_for(label)
    regions = case label.to_s
    when "a" then %w[words_a words_ab words_ac words_abc]
    when "b" then %w[words_b words_ab words_bc words_abc]
    when "c" then %w[words_c words_ac words_bc words_abc]
    else []
    end
    regions.flat_map { |r| send(r) || [] }.reject(&:blank?)
  end
end
