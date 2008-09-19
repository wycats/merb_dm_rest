module MerbRestServer
  extend Enumerable
    
  class << self
    
    def [](resource_name)
      resources.detect{|r| r.resource_name == resource_name.to_s}
    end
    
    def resources
      @resources ||= []
    end
    
    def each
      resources.each do |resource|
        yield resource
      end
    end  
    
    def resource_options
      out = {}
      resources.each do |r|
        out.merge!(r.resource_name => r.options)
      end
      out
    end
  end # class << self
end
