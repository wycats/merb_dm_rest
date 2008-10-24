if defined?(Merb::Plugins)

  $:.unshift File.dirname(__FILE__)

  load_dependency 'merb-slices'
  Merb::Plugins.add_rakefiles "merb_rest_server/merbtasks", "merb_rest_server/slicetasks"

  # Register the Slice for the current host application
  Merb::Slices::register(__FILE__)
  
  Merb.push_path(:lib,File.expand_path(File.join(File.dirname(__FILE__))) / "merb_rest_server" /"resources" )
  require 'merb-rest-formats'
  require 'yaml'
  
  # Slice configuration - set this in a before_app_loads callback.
  # By default a Slice uses its own layout, so you can swicht to 
  # the main application layout or no layout at all if needed.
  # 
  # Configuration options:
  # :layout - the layout to use; defaults to :merb_rest_server
  # :mirror - which path component types to use on copy operations; defaults to all
  Merb::Slices::config[:merb_rest_server][:layout] ||= :merb_rest_server
  
  # All Slice code is expected to be namespaced inside a module
  module MerbRestServer
    
    # Slice metadata
    self.description = "MerbRestServer is a chunky Merb slice!"
    self.version = "0.5.0"
    self.author = "Yehuda Katz"
    
    # Stub classes loaded hook - runs before LoadClasses BootLoader
    # right after a slice's classes have been loaded internally.
    def self.loaded
    end
    
    # Initialization hook - runs before AfterAppLoads BootLoader
    def self.init
    end
    
    # Activation hook - runs after AfterAppLoads BootLoader
    def self.activate
    end
    
    # Deactivation hook - triggered by Merb::Slices.deactivate(MerbRestServer)
    def self.deactivate
    end
    
    # Setup routes inside the host application
    #
    # @param scope<Merb::Router::Behaviour>
    #  Routes will be added within this scope (namespace). In fact, any 
    #  router behaviour is a valid namespace, so you can attach
    #  routes at any level of your router setup.
    #
    # @note prefix your named routes with :merb_rest_server_
    #   to avoid potential conflicts with global named routes.
    def self.setup_router(scope)
      # example of a named route
      scope.to(:controller => "rest") do |r|
        
        # GET
        r.match("/:resource(.:format)",       :method => :get).to(:action => "index"     )
        r.match("/:resource/:id(.:format)",   :method => :get).to(:action => "get"       )
        
        # PUT
        r.match("/:resource(.:format)",       :method => :put).to(:action => "put"       )
        r.match("/:resource/:id(.:format)",       :method => :put).to(:action => "put"       )  
        
        # POST
        r.match("/:resource(.:format)",       :method => :post).to(:action => "post"     )
        
        # DELETE
        r.match("/:resource(.:format)",       :method => :delete).to(:action => "delete" )
        r.match("/:resource/:id(.:format)",   :method => :delete).to(:action => "delete" )
        
        # OPTIONS
        r.match("/",                          :method => :options).to(:action => "options"  )
        r.match("/index(.:format)",           :method => :options).to(:action => "options"  )
        r.match("/:resource(.:format)",       :method => :options).to(:action => "options"  )
      end
      # scope.match(%r{\/(.*?)(.*)}, :method => :option).to(:action => "option", :resource => "path[1]")
      # scope.match(%r{(.*)}).defer_to do |req, params|
      #   m = req.path.match(%r{^/rest/?(.*?)(?:\.(.*))?$})
      #   parts = m[1].split("/")
      #   format = m[2]
      #   nests = parts.map { [parts.shift, parts.shift] }
      #   nests << [parts.shift] unless parts.empty?
      #   
      #   params = req.params.merge({ :controller => "merb_rest_server/rest", 
      #     :type => nests.last.first,
      #     :nests => nests[0..-2],
      #     :format => format})
      #     
      #   params.merge!(:action => nests.last.last ? req.method.to_s : "index")
      #   params.merge!(:id => nests.last.last) if nests.last.last
      #   params
      # end
      # scope.match('/index.:format').to(:controller => 'main', :action => 'index').name(:merb_rest_server_index)
    end
    
  end
  
  # Setup the slice layout for MerbRestServer
  #
  # Use MerbRestServer.push_path and MerbRestServer.push_app_path
  # to set paths to merb_rest_server-level and app-level paths. Example:
  #
  # MerbRestServer.push_path(:application, MerbRestServer.root)
  # MerbRestServer.push_app_path(:application, Merb.root / 'slices' / 'merb_rest_server')
  # ...
  #
  # Any component path that hasn't been set will default to MerbRestServer.root
  #
  # Or just call setup_default_structure! to setup a basic Merb MVC structure.
  MerbRestServer.setup_default_structure!
  
  # Add dependencies for other MerbRestServer classes below. Example:
  # dependency "merb_rest_server/other"
  
end