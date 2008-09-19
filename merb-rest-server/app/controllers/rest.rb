class MerbRestServer::Rest < MerbRestServer::Application
  only_provides :json, :xml

  def options
    opts = if params[:resource]
      r = MerbRestServer[params[:resource]]
      raise NotFound unless r
      r.options
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
    ""
  end
  
  def put
    ""
  end
  
  def delete
    ""
  end
  
  private 
  def command_processor
    @command_processor ||= MerbRestServer::CommandProcessor.new(params)
  end
end