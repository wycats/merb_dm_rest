class MerbRestServer::Rest < MerbRestServer::Application
  provides :json

  before do
    @type = Object.full_const_get(params[:type].camel_case)
  end
  
  def index
    types = @type.properties.map {|x| x.name}
    hsh = {}
    types.each do |type|
      hsh[type] = params[type].split(",") if params[type]
    end
    display @type.all(hsh)
  end
  
  def get
    @object = @type.get!(params[:id])
    display @object
  rescue DataMapper::ObjectNotFoundError
    self.status = 404
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