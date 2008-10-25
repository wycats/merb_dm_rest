module MerbRestServer
  # The RestResource is where all the definition of the resource is entered.
  # By inheriting from RestResource you make a resource available from your application.  
  # 
  # A resource exposes a DM model from your application for RESTful interaction
  # A resource is limited to one "Resrouce class" i.e. Person, Article etc. 
  # A DM model in your application however may be exposed via many RestResources
  #
  # A resource wraps a DM Model and provides it the ability to describe itself as 
  # a restful resource.  Available customizations for the resource include:
  #
  #  - resource name (path)
  #  - specify which HTTP method are allowed on the resource
  #  - Automatically provides discovery information via the OPTIONS HTTP method
  #  - default conditions to apply when finding resources
  #  - expose only certain fields (or all by deafult)
  #  - custom collection and member finders
  #  - DM query support.  e.g. :name.like, :age.gte etc
  #  - Integration with merb-auth so you can specify strategies to protect individual resources
  #  - Tie the resource to a particular repository
  #
  # MerbRestServer being a slice means that you can install the slice into your application
  # declare some RestResource(s) and your application will automatically provide those resources
  # restfully.  These are accessible to other ruby programs, javascript, anything that can access 
  # your server.
  # 
  # A DM model may be present in many different resources, each one exposing different ammounts of
  # iformation, at a different path, with different protection or with different finders for example.
  #
  # Use the RestResource class to declare your resources
  class RestResource 
    cattr_accessor :resource_class, :fields, :repository
    
    class_inheritable_reader :default_conditions, :member_finder, :collection_finder
    @@default_conditions = {}
    @@member_finder = @@collection_finder = nil
    
    REST_METHODS = %w(OPTIONS POST PUT GET DELETE).sort.freeze
    @@rest_methods = REST_METHODS.dup
    
    class << self
      
      # Use this method to expose the fields of your model you
      # want exposed.  Only these will be exposed regardless of what is requested.
      #
      # ====Example 
      #  class MyResource < MerbRestServer::RestResource
      #    resource_class Person
      #    expose_field :id, :name, :age
      #  end
      def expose_fields(*field_names)
        bad = field_names.flatten - field_names_from_class(resource_class, repository)
        raise ArgumentError, "#{bad.join} fields do not exist for the #{resource_class.name} model in the #{repository.name} repository." unless bad.blank?
        @fields = fields_from_class(resource_class, repository, field_names)
      end
      
      # Provides a list of field names that the resource provides
      def field_names
        fields.map{|p| p.keys.first}
      end
      
      # Provides access to the fields (as DM properties) that the resource provides  
      def fields
        @fields ||= fields_from_class(resource_class, repository)
      end
      
      # You _must_ set this to provide a resource class to the resource.  This is the minimum 
      # that is required to use a resource.
      #
      # ====Example
      #    class MyResource < MerbRestServer::RestResource
      #      resource_class Person
      #    end
      def resource_class(klass = nil)
        klass.nil? ? @resource_class : @resource_class = klass
      end
    
      # Set the repository to tie the resource to a particular repository.  
      #
      # ====Example
      #    class MyResource < MerbRestServer::RestResource
      #      resource_class Person
      #      respository :other_repository
      #    end
      def repository(repo = nil)
        if repo
          enforce!(repo => DataMapper::Repository)
          @repository = repo
        else
          @repository ||= DataMapper.repository(:default)
        end
        @repository
      end
    
      # Set the resource name.  The resource name is what is used to generate the relative url 
      # for where the resorce will be available
      #
      # ====Example
      #    class MyResource < MerbRestServer::RestResource
      #      resource_class Person
      #      resource_name "person"
      #    end
      #
      # In this example the resource will be available at "/person"
      # By Default the resource_name is DM's default storage name "people" 
      # and is then available at "/people"
      # You can also make it avialable at "person_specific" to make it avialble at "/person_specfic"
      # Currently nested resource names like "/person/specific" do not work :(
      def resource_name(name = nil)
        enforce!(name => [String, Symbol, NilClass])
        if name
          @resource_name = name.to_s
        else
          @resource_name ||= resource_class.storage_name(repository.name).to_s
        end
      end

      # Defines which HTTP methods to expose. 
      # Must be one of: OPTIONS POST PUT GET DELETE
      # By default all rest methods are available
      #
      # ====Example 
      #    class MyResource < MerbRestServer::RestResource
      #      resource_class Person
      #      rest_methods "GET", "PUT"
      #    end
      #
      # In this example, a resource is available to read (GET) and edit (UPDATE)
      # but not create, or delete.
      #
      # The OPTIONS method is always available
      def rest_methods(*methods)
        if methods.empty?
          @rest_methods ||= REST_METHODS.dup
        else
          @rest_methods = []
          add_rest_methods(*methods)
        end
        @rest_methods        
      end
      
      # Asks the resource if the provided HTTP method is alowed
      def rest_method?(meth)
        rest_methods.include?(meth.to_s.upcase)
      end
      
      # Resets these methods back to the default.
      def reset_rest_methods!
        @rest_methods = REST_METHODS.dup
      end

      # Use this to provide default conditions to your resource.  This
      # is a simple hash for fixed values.  If you need the flexibility
      # of knowing the request object to perform some logic you should use
      # custom finders
      #
      # ====Example
      #    class MyResource < MerbRestServer::RestResource
      #      resource_class Person
      #      default_conditions :level => "admin", :age.gt => 18
      #    end
      #
      def default_conditions(conditions = nil)
        if conditions
          raise "default conditions must be a Hash" unless conditions.kind_of?(Hash)
          @@default_conditions = conditions
        else
          @@default_conditions ||= {}
        end
      end
      
      # Set the collection_finder to specify a different finder method for your resource collection. 
      # default is :all, but you may require some additional logic.  
      # 
      # Use a Symbol or String to define a class method, or a block to be executed.
      #
      # When using the block, the request object, and the DM query will be passed in as an argument
      # Also, you are responsible for returning the collection yourself.
      #
      # ====Example
      #    class MyResource < MerbRestServer::RestResource
      #      resource_class Person
      #      collection_finder :my_finder 
      #    end
      #
      # ====Example
      #    class MyResource < MerbRestServer::RestResource
      #      resource_class Person
      #
      #      collection_finder do |request, query|
      #       if request.session.authenticated? && request.session.user.admin?
      #         Person.all(query)
      #       else
      #         request.session.user.account.people.all(query)
      #       end
      #     end
      #
      #    end
      def collection_finder(finder = nil, &block)
        finder = block if block
        return @@collection_finder if !finder && @@collection_finder
        
        @@collection_finder = case finder
        when Proc
          finder
        when nil
          :all
        when String, Symbol
          finder.to_sym
        else
          raise "collection_finder must be Symbol, String or block"
        end
      end
    
    
      # Set the member_finder to specify a different finder method for your resources members. 
      # default is :first, but you may require some additional logic.  
      # 
      # Use a Symbol or String to define a class method, or a block to be executed.
      #
      # When using the block, the request object, and query object will be passed in as an argument
      # Also, you are responsible for returning the member yourself.
      #
      # ====Example
      #    class MyResource < MerbRestServer::RestResource
      #      resource_class Person
      #      member_finder :my_finder 
      #    end
      #
      # ====Example
      #    class MyResource < MerbRestServer::RestResource
      #      resource_class Person
      #
      #      member_finder do |request|
      #       if request.session.authenticated? && request.session.user.admin?
      #         Person.first(query)
      #       else
      #         request.session.user.account.people.first(query)
      #       end
      #     end
      #
      #    end
      def member_finder(finder = nil, &block)
        finder = block if block
        return @@member_finder if !finder && @@member_finder
        
        @@member_finder = case finder
        when Proc
          finder
        when nil
          :first
        when String, Symbol
          finder.to_sym
        else
          raise "member_finder must be Symbol, String or block"
        end
      end

      # Add authentication to your resource.  
      #  +:none+ to turn it off (default)
      #  +:default+ run the default strategies of the application
      #  +Array Of String / Classes+ Pass in an array of strategies as per ensure_authenticated
      # (see merb-auth-core) 
      # 
      # ====Example
      #    class MyResource < MerbRestServer::RestResource
      #      resource_class Person
      #      authenticate_with :default 
      #    end
      #
      #    class MyResource < MerbRestServer::RestResource
      #      resource_class Person
      #      authenticate_with "OpenID", "BasicAuth"
      #    end
      def authenticate_with(*strategies)
        strategies = strategies.flatten
        
        if strategies.blank?
          @authenticate_with ||= []
        elsif strategies.first == :default || strategies.first == :none
          @authenticate_with = strategies.first
        else
          @authenticate_with = strategies
        end
      end
            
      # Provides the hash to output to the browser for the options method.
      def options
        {
          :resource_name => resource_name,
          :path          => "/#{resource_name}",
          :fields        => fields,
          :methods       => rest_methods
        }
      end

      def inherited(klass) #:nodoc:
        MerbRestServer.resources << klass
      end
      
      private 
      def set_rest_methods(*methods)
        tmp = methods.flatten.compact.uniq
        bad = tmp - REST_METHODS
        raise ArgumentError, "Non Existant Rest Method Specified #{bad.join(",")}" unless bad.blank?

        @rest_methods = tmp
      end
      
      def field_names_from_class(klass,repository)
        fields_from_class(resource_class, repository).map{|k| k.keys.first}
      end

      def fields_from_class(klass, repository, *fields)
        fields = fields.flatten
        klass.properties(repository.name).map do |p| 
          {p.name => p.primitive} if fields.blank? || fields.include?(p.name)
        end.compact
      end
    
      def add_rest_methods(*methods)
        set_rest_methods (rest_methods.dup << methods)
      end
          
      def block_rest_methods(*methods)
        set_rest_methods (rest_methods.dup - methods.flatten)
      end
    end # class << self
  end # RestResource
end