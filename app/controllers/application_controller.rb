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


  private


  def render_error( error, exception )
    notify( exception )

    respond_to do |format|
      format.html{ render :file => "#{Rails.root}/public/#{error}.html", :status => :not_found } 
    end  
  end


  def notify(exception)
    ExceptionNotifier::Notifier.exception_notification(request.env, exception,
      data: {message: 'an error happened'}).deliver
  end


end
