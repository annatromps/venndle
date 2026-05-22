Rails.application.routes.draw do
  devise_for :users

  root "puzzles#daily"
  get "/daily", to: "puzzles#daily", as: :daily
  get "/daily/:day_number", to: "puzzles#daily", as: :daily_puzzle
  get "/archive", to: "puzzles#archive", as: :archive

  resources :puzzles, only: [:index, :show, :new, :create]
  post   "/puzzles/:id/guess",     to: "puzzles#guess",       as: :puzzle_guess
  post   "/puzzles/:id/favourite", to: "favourites#create",   as: :puzzle_favourite
  delete "/puzzles/:id/favourite", to: "favourites#destroy"

  get "/admin", to: redirect("/admin/puzzles")
  namespace :admin do
    resources :puzzles
  end

  get "up" => "rails/health#show", as: :rails_health_check

  if Rails.env.development?
    get "/dev/reset", to: "dev#reset"
  end
end
