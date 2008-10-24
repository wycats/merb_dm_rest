module MerbRestServer
  class RestResource 
    cattr_accessor :resource_class, :resource_name, :fields, :repository
    
    # These are for setting your own custom finder methods on a resource.  
    # Use a symbol or string to call a metho.  Use a proc to have it executed in the controller context
    # You should find your collection in the case of a proc
    cattr_writer  :collection_finder, :member_finder
    
    class_inheritable_accessor :default_conditions
    @@default_conditions = {}
    
    

    REST_METHODS = %w(OPTIONS POST PUT GET DELETE).sort.freeze
    @@rest_methods = REST_METHODS.dup
    
    class << self
      def expose_fields(*field_names)
        bad = field_names.flatten - field_names_from_class(resource_class, repository)
        raise ArgumentError, "#{bad.join} fields do not exist for the #{resource_class.name} model in the #{repository.name} repository." unless bad.blank?
        @fields = fields_from_class(resource_class, repository, field_names)
      end
      
      def field_names
        fields.map{|p| p.keys.first}
      end
        
      def fields
        @fields ||= fields_from_class(resource_class, repository)
      end
      
      def resource_class(klass = nil)
        klass.nil? ? @resource_class : @resource_class = klass
      end
    
      def repository(repo = nil)
        if repo
          enforce!(repo => DataMapper::Repository)
          @repository = repo
        else
          @repository ||= DataMapper.repository(:default)
        end
        @repository
      end
    
      def resource_name(name = nil)
        if name
          @resource_name = name.to_s
        else
          @resource_name ||= resource_class.storage_name(repository.name)
        end
      end
    
      def resource_name=(name)
        enforce!(name => [String, Symbol])
        @resource_name = name.to_sym
      end
    
      def rest_methods(*methods)
        if methods.empty?
          @rest_methods ||= REST_METHODS.dup
        else
          @rest_methods = []
          add_rest_methods(*methods)
        end
        @rest_methods        
      end
      
      def rest_method?(meth)
        rest_methods.include?(meth.to_s.upcase)
      end
      
      def reset_rest_methods!
        @rest_methods = REST_METHODS.dup
      end

      def add_rest_methods(*methods)
        set_rest_methods (rest_methods.dup << methods)
      end
    
      def block_rest_methods(*methods)
        set_rest_methods (rest_methods.dup - methods.flatten)
      end
      
      def default_conditions(conditions = nil)
        if conditions
          raise "default conditions must be a Hash" unless conditions.kind_of?(Hash)
          @@default_conditions = conditions
        else
          @@default_conditions ||= {}
        end
      end
      
      def collection_finder
        @@collection_finder ||= :all
      end
      
      def collection_finder=(finder)
        @@collection_finder = case finder
        when Proc
          finder
        when String, Symbol
          finder.to_s.to_sym
        else
          raise "collection_finder must be Symbol, String or Proc"
        end
      end
      
      def member_finder 
        @@member_finder ||= :first
      end
      
      def member_finder=(finder)
        @@member_finder = case finder
        when Proc
          finder
        when String, Symbol
          finder.to_s.to_sym
        else
          raise "member_finder must be Symbol, String or Proc"
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

      def inherited(klass)
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
    end # class << self
  end # RestResource
end