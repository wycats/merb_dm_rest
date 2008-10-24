module MerbRestServer
  class CommandProcessor
    attr_reader :resource, :params
    attr_accessor :results
    
    def initialize(params)
      @params = params.to_mash
      @resource = MerbRestServer[params[:resource]]
      raise ArgumentError, "A resource needs to be specified" unless @resource    
    end
    
    def all
      @results = case resource.collection_finder
      when Proc
        resource.collection_finder.call(params)
      else
        @results = klass.send(resource.collection_finder, query.merge(resource.default_conditions))
      end
    end
    
    def first
      @results = case resource.member_finder
      when Proc
        resource.member_finder.call(params)
      else
        klass.send(resource.member_finder, query.merge(resource.default_conditions))
      end
    end
    
    def to_hash
      if @results.respond_to?(:each)
        collection_hash
      else
        member_hash(@results)
      end
    end
    
    def to_xml
      Merb::Rest::Formats::Xml.encode(to_hash)
    end
    
    def to_json
      JSON.generate(to_hash)
    end
    
    def to_rb
      Marshal.dump(to_hash)
    end
    
    def to_yaml
      YAML.dump(to_hash)
    end
    
    private 
    def query
      QueryParser.parse(resource.resource_name, params)
    end
    
    def klass
      @resource.resource_class
    end
    
    def collection_hash
      out = {resource.resource_name => []}
      @results.each do |r|
        out[resource.resource_name] << member_hash(r)
      end
      out
    end
    
    def member_hash(member)
      return {} if @results.nil?
      out = {}
      member.attributes.each do |name, value|
        out[name] = value
      end
      out
    end
  end
end