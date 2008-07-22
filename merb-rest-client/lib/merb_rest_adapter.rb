module DataMapper
  module Adapters
    class MerbRestAdapter < AbstractAdapter
      
      private
      def initialize(name, uri_or_options)
        super
        @uri = normalize_uri(uri_or_options)
      end
      
      public
      def create(resources)
        created = 0
        resources.each do |resource|
          repository = resource.repository
          model      = resource.model
          attributes = resource.dirty_attributes

          # TODO: make a model.identity_field method
          identity_field = model.key(repository.name).detect { |p| p.serial? }

          paramteters = {resource_name(model) => model.value_paramters }
          # statement = create_statement(repository, model, attributes.keys, identity_field)
          # bind_values = attributes.values

          # result = execute(statement, *bind_values)
          result = post(query, URI.escape(parameters.to_params))

          if result.to_i == 1
            if identity_field
              identity_field.set!(resource, result.insert_id)
            end
            created += 1
          end
        end
        created
      end
      
      private
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

      
      def fields_parameters
      end
      
      def conditions_parameters
      end
      
      def value_parameters; end
      
      def order_parameters
      end
      
      def links_parameters; end
      
      def group_by_paramters; end 
      
      def property_to_column_name; end
      
      def quote_resource_name; end
      
      def resource_name(query) 
       query.model.storage_name(query.repository.name)
      end
      
      def url_for_resource
        
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
        query =     uri_or_options.to_a.map { |pair| pair.join('=') }.join('&')
        query = nil if query == ""

        return Addressable::URI.new(
          scheme, user, password, host, port, database, query, nil
        )
      end
      
      
    end # MerbDataMapperRest
  end # Adapters
end # DataMapper