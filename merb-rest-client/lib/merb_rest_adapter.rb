module DataMapper
  module Adapters
    class MerbRestAdapter < AbstractAdapter
      
      private
      def initialize(name, uri_or_options)
        super
        @format = :json
        @uri = normalize_uri(uri_or_options)
      end
      
      public
      def create(resources)
        created = 0
        resources.each do |resource|
          repository    = resource.repository
          model         = resource.model
          attributes    = resource.dirty_attributes
          storage_name  = model.storage_name(repository.name)
          
          result = api_post(storage_name, storage_name.singular => attributes_hash(attributes) )
          created += 1
        end
        created
      end
        # resources.each do |resource|
        #   repository = resource.repository
        #   model      = resource.model
        #   attributes = resource.dirty_attributes
        # 
        #   # TODO: make a model.identity_field method
        #   identity_field = model.key(repository.name).detect { |p| p.serial? }
        # 
        #   paramteters = {resource_name(model) => model.value_paramters }
        #   # statement = create_statement(repository, model, attributes.keys, identity_field)
        #   # bind_values = attributes.values
        # 
        #   # result = execute(statement, *bind_values)
        #   result = post(query, URI.escape(parameters.to_params))
        # 
        #   if result.to_i == 1
        #     if identity_field
        #       identity_field.set!(resource, result.insert_id)
        #     end
        #     created += 1
        #   end
        # end
        # created

      def read_one(query)
        response = api_get(resource_name(query).to_s, api_query_parameters(query))
        fields = query.fields.map{|f| f.name.to_s}
        result = parse_results(response.body).first
        value_array = fields.map{|f| result[f]}
        query.model.load(value_array, query)      
      end

      def read_many(query)
        Collection.new(query) do |collection|
          result = api_get(resource_name(query).to_s, api_query_parameters(query))
          values_array =[]
          fields = query.fields.map{|f| f.name.to_s}
          results_array = parse_results(result.body).map do |result|
            fields.map{|f| result[f]}
          end
          results_array.each do |result|
            collection.load(result)
          end               
        end
      end
      
      protected
      def api_get(path, options = {})
        abstract_request( 
                          :class      => Net::HTTP::Get,
                          :path       => path,
                          :seperator  => "&",
                          :data       => options
                        )
      end
      
      def api_put(path, data)
        abstract_request( 
                          :class      => Net::HTTP::Put,
                          :path       => path,
                          :data       => data
                        )
      end
      
      def api_delete(path, data)
        abstract_request( 
                          :class      => Net::HTTP::Delete,
                          :path       => path,
                          :data       => data
                        )
      end
      
      def api_post(path, data) 
        abstract_request( 
                          :class      => Net::HTTP::Post,
                          :path       => path,
                          :data       => data
                        )
      end
      
      def api_options(path, data)
        abstract_request(
                          :class      => Net::HTTP::Options,
                          :path       => path,
                          :data       => data
                        )
      end        
                      
      def abstract_request(options)
        raise "Require a :path and :class key for an abstract request" unless [:path, :class].all?{|k| options.keys.include?(k)}
        klass =     options[:class]
        path =      @uri.path / options[:path] 
        data =      options.fetch(:data,{})
        seperator = options.fetch(:seperator, ";")

        req = klass.new(path)
        req.basic_auth @uri.user, @uri.password
        req.set_form_data(data, seperator)
        res = Net::HTTP.new(@uri.host, @uri.port).start{|http| http.request(req)}
        case res
        when Net::HTTPSuccess, Net::HTTPRedirection
          res
        else
          res.error!
        end
      end
      
      def api_query_parameters(query)
        parameters = condition_parameters(query.conditions)
        parameters.merge!(order_parameters(query.order)) unless query.order.blank?
        parameters.merge!("fields"  => query.fields.map{|f| f.name.to_s}) unless query.fields.blank?
        parameters.merge!("limit"   => query.limit) if query.limit
        parameters.merge!("offset"  => query.offset) if query.offset && query.offset > 1
        parameters.merge!("unique"  => query.unique?) if query.unique?
        parameters
      end
      
      def field_parameters(fields)
        out = []
        fields.each{|f| out << f.name}
        {"fields" => out}
      end
      
      def condition_parameters(conditions)
        out = {}
        conditions.each do |operator, prop, value|
          out.merge!("#{prop.name}.#{operator}" => value)
        end
        out
      end
      
      def order_parameters(order)
        out = []
        order.each do |ord|
          out << "#{ord.property.name}.#{ord.direction}"
        end
        {"order" => out}
      end
      
      def attributes_hash(hash)
        out = {}
        hash.each do |k,v|
          case k
          when Property
            out[k.name.to_s] = v
          else
            out[k.to_s] = v
          end
        end
        out
      end
    
      def parse_results(data)
        case @format
        when :json
          data.blank? ? {} : JSON.parse(data)
        end
      end
      
      def resource_name(query) 
       query.model.storage_name(query.repository.name)
      end      
      
      def normalize_uri(uri_or_options)
        if String === uri_or_options
          uri_or_options = Addressable::URI.parse(uri_or_options)
        end
        if Addressable::URI === uri_or_options
          uri_or_options.scheme = "http"
          return uri_or_options.normalize
        end

        user =      uri_or_options.fetch(:username)
        password =  uri_or_options.fetch(:password)
        host =      uri_or_options.fetch(:host, "")
        port =      uri_or_options.fetch(:port)
        database =  uri_or_options.fetch(:database)
        scheme =    uri_or_options.fetch(:scheme, "http")
        @format =   uri_or_options.fetch(:format, :json)
        query =     uri_or_options.to_a.map { |pair| pair.join('=') }.join('&')
        query = nil if query == ""

        return Addressable::URI.new(
          scheme, user, password, host, port, database, query, nil
        )
      end
      
      
    end # MerbDataMapperRest
  end # Adapters
end # DataMapper