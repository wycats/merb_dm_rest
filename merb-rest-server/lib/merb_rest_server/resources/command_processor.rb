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
      @results = klass.all(query)
    end
    
    def first
      @results = klass.first(query)
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