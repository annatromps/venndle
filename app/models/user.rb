class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :puzzles
  has_many :attempts
  has_many :game_sessions
  has_many :favourites, dependent: :destroy
  has_many :favourite_puzzles, through: :favourites, source: :puzzle
  has_many :ratings, dependent: :destroy

  validates :username, presence: true, uniqueness: true
end
