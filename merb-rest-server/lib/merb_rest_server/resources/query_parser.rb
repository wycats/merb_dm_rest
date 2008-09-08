module MerbRestServer
  module QueryParser
    
    def self.parse(resource_name, params)
      params = params.dup
      r = MerbRestServer[resource_name]
      raise Merb::Controller::NotFound unless r
      DataMapper::Query.new(r.repository, r.resource_class, extract_params_for_query(r.resource_class, params, r))
    end
    
    private 
    def self.extract_params_for_query(klass, params, resource)
      out = {}
      out[:limit]       = params.delete("limit").to_i   if params["limit"]
      out[:offset]      = params.delete("offset").to_i  if params["offset"]
      out[:unique]      = params.delete("unique")       unless params["unique"].nil?
      out[:conditions]  = extract_query_conditions(resource, params.delete("q")) if params["q"]
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
    
    
    def self.typecast_value(r, field, value)
      primitive = r.resource_class.properties[field].primitive
      if    primitive == String;  value.to_s
      elsif primitive == Integer; value.to_i
      elsif [Float].include?(primitive);   value.to_f
      elsif [TrueClass, FalseClass].include?(primitive); value != "0"
      elsif primitive == DateTime
        DateTime.parse(value)
      elsif primitive == Date
        d = DateTime.parse(value)
        Date.new(d.year, d.month, d.day)
      else
        raise "Can't typecast #{field.inspect} with #{value}"
      end
    end
    
    def self.extract_query_conditions(resource, conditions)
      out = {}
      conditions.each do |k, v|    
        field, operator = k.split(".").map{|p| p.to_sym if p}
        next unless resource.field_names.include?(field)
        cond = operator.nil? ? field : field.send(operator)        
        out[cond] = typecast_value(resource, field, v)
      end
      out 
    end
  end
end