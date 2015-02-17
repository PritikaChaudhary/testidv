class HomeController < ApplicationController
  def index
  end
  
  def test
    @contact = Infusionsoft.data_load('Contact', 925, [:FirstName, :LastName])
  end
end
