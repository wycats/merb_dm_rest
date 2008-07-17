class MerbRestServer::Rest < MerbRestServer::Application
  provides :json

  before do
    begin
      @type = Object.full_const_get(params[:type].camel_case)
    rescue NameError, NoMethodError
      throw :halt, display({}, :status => 400)
    end
  end
  
  def options
    headers["Allow"] = "GET, PUT"
    display @type.properties.inject({}) {|a,x| a[x.name] = x.type; a }
  end
  
  # Index supports:
  #   /rest/foo
  #   /rest/foo?id=1,2
  #   /rest/foo?name=he%25&query_type=like
  #
  # Query type specifies what kind of query to use:
  #   /rest/foo?name=he%25&query_type=like
  # becomes:
  #   Foo.all(:name.like => "he%")
  def index
    types = @type.properties.map {|x| x.name}
    query_type = params[:query_type] || :eql
    hsh = {}
    types.each do |type|
      hsh[type.send(query_type)] = params[type].split(",") if params[type]
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