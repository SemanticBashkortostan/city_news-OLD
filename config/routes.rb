CityNews::Application.routes.draw do
  ActiveAdmin.routes(self)

  mount Feedbacks::Engine, :at => "/", :as => "feedbacks" 

  root :to => "feeds#index"
  devise_for :users

  match '/about' => 'application#about'

  match '/goto' => 'feeds#goto', :as => 'feeds_goto'
  match ':city' => 'feeds#index', :as => 'feeds_city'
  match '/' => 'feeds#index', :as => 'feeds'

  unless Rails.application.config.consider_all_requests_local
    match '*not_found', to: 'application#render_404'
  end

end