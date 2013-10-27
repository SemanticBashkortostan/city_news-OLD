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
class ApplicationController < ActionController::Base
  protect_from_forgery


  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, :alert => exception.message
  end

  unless Rails.application.config.consider_all_requests_local
    rescue_from Exception, :with => lambda { |exception| render_error( 404, exception ) }
  end


  def render_404    
    render :file => "#{Rails.root}/public/404.html", :status => :not_found
  end


  def about
    render "pages/about"
  end


  private


  def render_error( error, exception )
    notify( exception )

    respond_to do |format|
      format.html{ render :file => "#{Rails.root}/public/#{error}.html", :status => :not_found } 
      format.any{ render :file => "#{Rails.root}/public/#{error}.html", :status => :not_found } 
    end  
  end


  def notify(exception)
    Honeybadger.notify exception
  end


end