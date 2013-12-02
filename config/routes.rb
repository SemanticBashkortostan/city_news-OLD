#
# CityNews - news aggregator software
# Copyright (C) 2013  Idris Yusupov
#
# This file is part of CityNews.
#
# CityNews is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# CityNews is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with CityNews.  If not, see <http://www.gnu.org/licenses/>.
#

CityNews::Application.routes.draw do
  ActiveAdmin.routes(self)

  mount Feedbacks::Engine, :at => "/", :as => "feedbacks" 

  root :to => "feeds#index"
  devise_for :users

  match '/about' => 'application#about'

  match '/goto' => 'feeds#goto', :as => 'feeds_goto'
  match ':city' => 'feeds#index', :as => 'feeds_city'

  resources :feeds, only: [:show, :index]


  match 'content_extraction/index' => 'content_extraction#index' 
  match 'content_extraction/extract' => 'content_extraction#extract' 


  # Api section
  namespace :api do
    namespace :v1 do
      resources :cities do
        resources :news do
        end
      end
      resources :news, :only => [:show, :index] do
        
      end      
    end
  end

  unless Rails.application.config.consider_all_requests_local
    match '*not_found', to: 'application#render_404'
  end

end