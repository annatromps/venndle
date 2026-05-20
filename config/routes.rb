Rails.application.routes.draw do
  devise_for :users

  root "puzzles#daily"
  get "/daily", to: "puzzles#daily"
  get "/archive", to: "puzzles#archive", as: :archive

  resources :puzzles, only: [:index, :show, :new, :create]
  post "/puzzles/:id/guess",   to: "puzzles#guess",   as: :puzzle_guess
  post "/puzzles/:id/hint",    to: "puzzles#hint",    as: :puzzle_hint
  post "/puzzles/:id/give_up", to: "puzzles#give_up", as: :puzzle_give_up

  get "/admin", to: redirect("/admin/puzzles")
  namespace :admin do
    resources :puzzles
  end

  get "up" => "rails/health#show", as: :rails_health_check

  if Rails.env.development?
    get "/dev/reset", to: "dev#reset"
  end
end
