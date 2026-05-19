Rails.application.routes.draw do
  devise_for :users

  root "puzzles#daily"
  get "/daily", to: "puzzles#daily"

  resources :puzzles, only: [:index, :show, :new, :create]
  post "/puzzles/:id/guess", to: "puzzles#guess", as: :puzzle_guess

  namespace :admin do
    resources :puzzles
  end

  get "up" => "rails/health#show", as: :rails_health_check

  if Rails.env.development?
    get "/dev/reset", to: "dev#reset"
  end
end
