Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: 'users/registrations' }

  root "puzzles#daily"
  get "/daily", to: "puzzles#daily", as: :daily
  get "/daily:number", to: "puzzles#show_by_daily_number", constraints: { number: /\d+/ }, as: :daily_number
  get "/archive", to: "puzzles#archive", as: :archive

  resources :puzzles, only: [:index, :show, :new, :create]
  post   "/puzzles/:id/guess",         to: "puzzles#guess",     as: :puzzle_guess
  post   "/puzzles/:id/hint",          to: "puzzles#hint",      as: :puzzle_hint
  post   "/puzzles/:id/give_up",       to: "puzzles#give_up",   as: :puzzle_give_up
  post   "/puzzles/:id/favourite",     to: "favourites#create", as: :puzzle_favourite
  delete "/puzzles/:id/favourite",     to: "favourites#destroy"
  post   "/puzzles/:puzzle_id/rating", to: "ratings#create",    as: :puzzle_rating

  get "/my/stats", to: "stats#show", as: :my_stats
  post "/toggle_admin_view", to: "application#toggle_admin_view", as: :toggle_admin_view

  get "/admin", to: redirect("/admin/puzzles")
  namespace :admin do
    resources :puzzles do
      member do
        patch :schedule
        patch :unschedule
      end
    end
  end

  get "/:id", to: "puzzles#show", constraints: { id: /\d+/ }

  get "up" => "rails/health#show", as: :rails_health_check

  if Rails.env.development?
    get "/dev/reset", to: "dev#reset"
  end
end
