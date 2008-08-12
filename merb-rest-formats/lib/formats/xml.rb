require 'rexml/document'
require 'rexml/element'

module Merb
  module Rest
    module Formats
      module Xml
        
        def self.encode(hash)
          Encode.encode(hash)
        end
        
        def self.decode(xml_string)
          Decode.decode(xml_string)
        end
        
        module Encode
            class << self
              include REXML

              def encode(args)
                el = encode_pair(nil, args)
                case args
                when Array
                  args.each do |v|
                    el << encode_pair(nil, v)
                  end
                when Hash, Struct
                  args.each do |k,v|
                    el << encode_pair(k,v)
                  end
                end
                el.root.to_s
              end

              def encode_pair(name, value)

                case value
                when Fixnum 
                  el = Element.new("i4")
                  el.attributes['name'] = name.to_s  unless name.nil?
                  el.text = value
                  el

                when Bignum
                  if value >= -(2**31) and value <= (2**31-1)
                    el = Element.new("i4")
                    el.attributes['name'] = name.to_s  unless name.nil?
                    el.text = value
                    el
                  else
                    raise "Bignum is too big! Must be signed 32-bit integer!"
                  end

                when Array
                  el = Element.new("list")
                  el.attributes['name'] = name.to_s  unless name.nil?
                  value.each{|v| el << encode_pair(nil, v)}
                  el

                when TrueClass, FalseClass
                  el = Element.new("boolean")
                  el.attributes['name'] = name.to_s  unless name.nil?
                  el.text = value ? 1 : 0
                  el

                when String, Symbol
                  el = Element.new("string")
                  el.attributes['name'] = name.to_s  unless name.nil?
                  el.text = value
                  el

                when Float
                  el = Element.new("double")
                  el.attributes['name'] = name.to_s  unless name.nil?
                  el.text = value
                  el

                when Struct
                  el = Element.new("struct")
                  el.attributes['name'] = name.to_s  unless name.nil?
                  value.members.collect do |key| 
                    val = value[key]
                    el << encode_pair(key, val)
                  end
                  el

                when Hash
                  el = Element.new("struct")
                  el.attributes['name'] = name.to_s  unless name.nil?
                  value.collect do |key, val|
                    el << encode_pair(key, val)
                  end
                  el

                when Time, Date, ::DateTime
                  el = Element.new("dateTime.iso8601")
                  el.attributes['name'] = name.to_s  unless name.nil?
                  el.text = value.strftime("%Y%m%dT%H:%M:%S%Z")
                  el

                when DateTime
                  el = Element.new("dateTime.iso8601")
                  el.attributes['name'] = name.to_s  unless name.nil?
                  el.text = format("%.4d%02d%02dT%02d:%02d:%02d", *value.to_a)
                  el
                  
                when NilClass
                  el = Element.new("nil")
                  el.attributes['name'] = name.to_s  unless name.nil?
                  el
                  
                when Base64
                  el = Element.new("base64")
                  el.attributes['name'] = name.to_s  unless name.nil?
                  el.text = value.encoded
                  el
                else 
                  raise "Param Not encodable! #{value}"

                end  
              end    
            end # class << self
          end # Encode
        
        module Decode
          class Node
            attr_accessor :name, :attributes, :children, :type
            cattr_accessor :typecasts, :available_typecasts
                        
            def initialize(type, attributes = {})
              @children = []
              @attributes = attributes
              @type = type
              @name = attributes["name"]
            end
            
            def add_node(node)
              @text = true if node.is_a? String
              @children << node
            end
            
            def munge
              result = case type
              when "args"
                out = {}
                if children.size == 1
                  out[:args] = children.first.munge
                end
                return out
              when "list"
                children.map{|c| c.munge}
              when "struct"
                result = {}
                children.each do |n|
                  raise "children of struct must have a name attribute" unless n.name
                  result.merge!(n.munge)
                end
                result
              else
                typecast_value(self)
              end
              
              if @name
                {@name.to_sym => result}
              else
                result
              end
            end
            
            def typecast_value(value)
              return value unless @type
              proc = self.class.typecasts[@type]
              proc.call(value)
            end
            
          end
          
          Node.typecasts = {}
          Node.typecasts["nil"]               = lambda{|n| nil}
          Node.typecasts["boolean"]           = lambda{|n| n.children.first == "1"}
          Node.typecasts["string"]            = lambda{|n| n.children.join}
          Node.typecasts["i4"]                = lambda{|n| n.children.first.to_i}
          Node.typecasts["double"]            = lambda{|n| n.children.first.to_f}
          Node.typecasts["dateTime.iso8601"]  = lambda do |n| 
            str = n.children.first
            begin
            DateTime.parse(str)
            rescue e => ArgumentError
              raise "wronge dateTime.iso8601 format " + str
            end
          end    
          
          
          def self.decode(xml)
            stack = []
            parser = REXML::Parsers::BaseParser.new(xml)
            while true
              event = parser.pull
              case event[0]
              when :end_document
               break
              when :end_doctype, :start_doctype
               # do nothing
              when :start_element
               stack.push Node.new(event[1], event[2])
              when :end_element
               if stack.size > 1
                 temp = stack.pop
                 stack.last.add_node(temp)
               end
              when :text, :cdata
               stack.last.add_node(event[1]) unless event[1].strip.length == 0
              end
            end           
            stack.pop.munge
          end # self.decode
        end # Decode
        
        
      end # XML
    end #Formats
  end # DmRest
end # Merb