class Api::V1::CitiesController < Api::V1::BaseController

  def show
    @city = TextClass.find params[:id]
  end


  def index
    @cities = TextClass.all
  end

end
