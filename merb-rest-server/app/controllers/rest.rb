class MerbRestServer::Rest < MerbRestServer::Application
  provides :json
  
  def index
    ""
  end
  
  def get
    type = Object.full_const_get(params[:type].camel_case)
    @object = type.get!(params[:id])
    display @object
  end
  
  def post
    ""
  end
  
  def put
    ""
  end
  
  def delete
    ""
  end
  
end