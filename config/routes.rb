Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: 'users/registrations' }

  root "puzzles#daily"
  get "/daily", to: "puzzles#daily", as: :daily
  get "/daily:number", to: "puzzles#show_by_daily_number", constraints: { number: /\d+/ }, as: :daily_number
  get "/archive", to: "puzzles#archive", as: :archive
  get "/practice", to: "puzzles#practice", as: :practice

  resources :puzzles, only: [:index, :show, :new, :create]
  post   "/puzzles/:id/guess",         to: "puzzles#guess",        as: :puzzle_guess
  post   "/puzzles/:id/hint",          to: "puzzles#hint",         as: :puzzle_hint
  post   "/puzzles/:id/give_up",       to: "puzzles#give_up",      as: :puzzle_give_up
  post   "/puzzles/:puzzle_id/feedback", to: "puzzle_feedbacks#create", as: :puzzle_feedback
  post   "/puzzles/:id/favourite",     to: "favourites#create", as: :puzzle_favourite
  delete "/puzzles/:id/favourite",     to: "favourites#destroy"
  post   "/puzzles/:puzzle_id/rating", to: "ratings#create",    as: :puzzle_rating

  get "/my/stats", to: "stats#show", as: :my_stats
  post "/toggle_admin_view", to: "application#toggle_admin_view", as: :toggle_admin_view

  get "/admin", to: redirect("/admin/puzzles")
  namespace :admin do
    resources :puzzles do
      collection do
        get :wrong_guesses
      end
      member do
        patch :schedule
        patch :unschedule
      end
    end
  end

  get "/:id", to: "puzzles#show", constraints: { id: /\d+/ }

  get "manifest"       => "rails/pwa#manifest",       as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get "up" => "rails/health#show", as: :rails_health_check

  if Rails.env.development?
    get "/dev/reset", to: "dev#reset"
  end
end
