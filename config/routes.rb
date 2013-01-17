CityNews::Application.routes.draw do
  ActiveAdmin.routes(self)

  authenticated :user do
    root :to => 'home#index'
  end
  root :to => "home#index"
  devise_for :users
  resources :users


  match 'feeds/:city' => 'feeds#index', :as => 'feeds_city'
  resources :feeds

end