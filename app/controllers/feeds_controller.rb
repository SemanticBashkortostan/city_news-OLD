#coding: utf-8

class FeedsController < ApplicationController

  def index
    @title = TextClass.find_by_eng_name( params[:city].capitalize ).name if params[:city]

    if params[:city]
      @feeds = Feed.where( :assigned_class_id => TextClass.find_by_eng_name( params[:city].capitalize ) ).order 'published_at desc'
    else
      @feeds = Feed.order 'published_at desc'
    end
    @feeds = @feeds.page params[:page]
    @grouped_feeds = @feeds.group_by{ |feed| feed.published_at.strftime("%d-%m-%Y") }
  end

end
