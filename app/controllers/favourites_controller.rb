class FavouritesController < ApplicationController
  def create
    puzzle = Puzzle.find(params[:id])
    if user_signed_in?
      Favourite.find_or_create_by(user: current_user, puzzle: puzzle)
    else
      favs = (session["guest_favourites"] || []).dup
      favs << puzzle.id unless favs.include?(puzzle.id)
      session["guest_favourites"] = favs
    end
    render json: { favourited: true }
  end

  def destroy
    puzzle = Puzzle.find(params[:id])
    if user_signed_in?
      current_user.favourites.where(puzzle: puzzle).destroy_all
    else
      session["guest_favourites"] = (session["guest_favourites"] || []).reject { |id| id == puzzle.id }
    end
    render json: { favourited: false }
  end
end
