class MerbRestServer::Rest < MerbRestServer::Application
  only_provides :json, :xml
  
  before :get_resource
  before :check_allowed_method, :exclude => [:options]
  before :run_authentication

  # Returns the options for the given resource.
  # If no resource is given, the options for all resources are provided
  def options
    opts = if @resource
      @resource.options
    else
      MerbRestServer.resource_options
    end
    display opts
  end
  
  # Retuns an array of objects
  def index
    command_processor.all
    display command_processor
  end
  
  # Returns a single object
  def get
    command_processor.first
    raise NotFound if command_processor.results.nil?
    display command_processor
  end
  
  # Creates a new object
  def post
    begin
      @result = @resource.resource_class.new(params[params[:resource]])
      if @result.save
        self.status =  201
        command_processor.results = @result
      else
        raise Forbidden
      end
      display command_processor
    rescue => e
      raise Forbidden
    end
  end
  
  def put
    raise Unimplmented
  end
  
  def delete
    raise Unimplmented
  end
  
  private 
  
  def run_authentication
    return unless @resource
    return if @resource.authenticate_with == :none
    
    case @resource.authenticate_with
    when :default
      ensure_authenticated
    when nil, []
      return ""
    else
      ensure_authenticated @resource.authenticate_with
    end
  end
  
  def get_resource
    @resource ||= MerbRestServer[params[:resource]]
    raise NotFound if params[:resource] && !@resource
    @resource
  end
  
  def check_allowed_method
    raise MethodNotAllowed unless @resource.rest_method?(request.method)
  end
  
  def command_processor
    @command_processor ||= MerbRestServer::CommandProcessor.new(request)
  end
end