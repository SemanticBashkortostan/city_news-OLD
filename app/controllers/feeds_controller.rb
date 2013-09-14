#coding: utf-8
#
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

class FeedsController < ApplicationController


  def index
    if params[:city] && params[:city] != "all"
      text_class = TextClass.find_by_eng_name( params[:city].capitalize )
      @title = text_class.name if params[:city]
      @description = "Новости #{text_class.prepositional_name}."
      @feeds = Feed.with_text_klass( text_class.id ).order 'published_at desc'
    else
      @feeds = Feed.includes(:text_class).where('text_class_id is not null').order 'published_at desc'
    end
    @feeds = @feeds.page params[:page]
    @grouped_feeds = @feeds.where('published_at is not null').group_by{ |feed| feed.published_at.strftime("%d-%m-%Y") }
    respond_to do |format|
      format.html
      format.json{ render :json => @feeds }
      format.xml{ render :xml => @feeds }
    end
  end


  def goto
    redirect_to params[:url]
  end

end