module MerbRestServer
  module QueryParser
    
    def self.parse(resource_name, params)
      params = params.dup
      r = MerbRestServer[resource_name]
      raise Merb::Controller::NotFound unless r
      DataMapper::Query.new(r.repository, r.resource_class, extract_params_for_query(r.resource_class, params))
    end
    
    private 
    def self.extract_params_for_query(klass, params)
      out = {}
      out[:limit]   = params.delete("limit").to_i   if params["limit"]
      out[:offset]  = params.delete("offset").to_i  if params["offset"]
      out.merge!(extract_fields_for_class!(klass, params))
      out
    end
    
    def self.extract_fields_for_class!(klass, params)
      return {} unless params["fields"]
      out = []
      params.delete("fields").each do |field|
        out << klass.properties[field.to_sym]
      end
      {:fields => out.compact}
    end
  end
end