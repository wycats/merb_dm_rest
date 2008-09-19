class MerbRestServer::Rest < MerbRestServer::Application
  only_provides :json, :xml
  
  before :get_resource, :exclude => [:options]
  before :check_allowed_method, :exclude => [:options]

  def options
    opts = if params[:resource]
      get_resource
      @resource.options
    else
      MerbRestServer.resource_options
    end
    display opts
  end
  
  def index
    command_processor.all
    display command_processor
  end
  
  def get
    command_processor.first
    raise NotFound if command_processor.results.nil?
    display command_processor
  end
  
  def post
    @result = @resource.resource_class.new(params[params[:resource]])
    if @result.save
      self.status =  201
      command_processor.results = @result
    else
      raise Forbidden
    end
    display command_processor
  end
  
  def put
    ""
  end
  
  def delete
    ""
  end
  
  private 
  def get_resource
    @resource ||= MerbRestServer[params[:resource]]
    raise NotFound unless @resource
    @resource
  end
  
  def check_allowed_method
    raise MethodNotAllowed unless @resource.rest_method?(request.method)
  end
  
  def command_processor
    @command_processor ||= MerbRestServer::CommandProcessor.new(params)
  end
end