CityNews::Application.routes.draw do
  ActiveAdmin.routes(self)

  root :to => "feeds#index"
  devise_for :users

  match ':city' => 'feeds#index', :as => 'feeds_city'
  match '/' => 'feeds#index', :as => 'feeds'

end