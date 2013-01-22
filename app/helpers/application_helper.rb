module ApplicationHelper

  # Установка заголовка для страницы из view
  def page_title( page_title )
    content_for(:title) { page_title }
  end


  def page_description(descr)
    content_for(:description){ descr }
  end

end
