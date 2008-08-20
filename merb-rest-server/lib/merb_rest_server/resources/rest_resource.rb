module MerbRestServer
  class RestResource 
    attr_accessor :resource_class, :resource_name, :fields, :repository
    
    REST_METHODS = %w(OPTIONS POST PUT GET DELETE).sort.freeze
    
    def initialize(klass, opts = {})
      enforce!(opts[:repository] => DataMapper::Repository) if opts[:repository]
      enforce!(klass => Class)
      enforce!(opts[:methods] => Array) if opts[:methods]
      
      
      @resource_class = klass
      @repository     = opts.fetch(:repository, DataMapper.repository(:default))
      @resource_name  = klass.storage_names[@repository.name]
      @rest_methods   = opts.fetch(:methods, REST_METHODS.dup)
      
      @fields = field_names_from_class(@resource_class, @repository)
    end
    
    def expose_fields(*field_names)
      bad = field_names.flatten - field_names_from_class(resource_class, repository)
      raise ArgumentError, "#{bad.join} fields do not exist for the #{resource_class.name} model in the #{repository.name} repository." unless bad.blank?
      @fields = field_names.flatten
    end
    
    def repository=(repo)
      enforce!(repo => DataMapper::Repository)
      @repository = repo
    end
    
    def resource_name=(name)
      enforce!(name => [String, Symbol])
      @resource_name = name.to_sym
    end
    
    def rest_methods
      @rest_methods ||= []
    end
    def add_rest_methods(*methods)
      set_rest_methods (@rest_methods.dup << methods)
    end
    
    def block_rest_methods(*methods)
      set_rest_methods (@rest_methods.dup - methods.flatten)
    end
    
    def set_finder
      raise ArgumentError, "You need to specify a block" unless block_given?
      
    end
    
    def to_xml
    end
    
    private 
    def set_rest_methods(*methods)
      tmp = methods.flatten.compact.uniq
      bad = tmp - REST_METHODS
      raise ArgumentError, "Non Existant Rest Method Specified #{bad.join(",")}" unless bad.blank?
      
      @rest_methods = tmp
    end
    
    def field_names_from_class(klass, repository)
      klass.properties(repository.name).map{|p| p.name} 
    end
    
  end # RestResource
end