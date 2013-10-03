class Api::V1::NewsController < Api::V1::BaseController

  def index    
    params[:page] ||= 1
    params[:per_page] ||= 30

    scope = Feed

    if params[:published_at_less].present?
      scope = scope.where('published_at < ?', Time.parse(params[:published_at_less]))
    end

    if params[:published_at_more].present?
      scope = scope.where('published_at > ?', Time.parse(params[:published_at_more]))
    end

    if params[:city_id].present?
      scope = scope.where(:text_class_id => params[:city_id])
    end
    
    @news = scope.page(params[:page]).per(params[:per_page]).order("published_at desc")
    @pages_data = { :per_page => params[:per_page], :pages_count => @news.total_pages, :current_page => params[:page] }
  end

end
