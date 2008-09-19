require File.dirname(__FILE__) + '/../spec_helper'

describe "MerbRestServer::Rest (controller)" do
  
  # Feel free to remove the specs below
  
  before :all do
    Merb::Router.prepare { |r| r.add_slice(:MerbRestServer, :path => "rest", :default_routes => false) } if standalone?
  end
  
  after :all do
    Merb::Router.reset! if standalone?
    class PersonResource < MerbRestServer::RestResource
      resource_class Person
    end
    class CatResource < MerbRestServer::RestResource
      resource_class Cat
    end
    class ZooResrouce < MerbRestServer::RestResource
      resource_class Zoo
      resource_name "zoo"
      rest_methods "GET"
    end
  end

  require File.dirname(__FILE__) + '/../spec_helper'    
  
  before(:all) do
    Person.auto_migrate!
    Cat.auto_migrate!
    (0..100).of { Person.generate }   
    (0..100).of { Cat.generate}
  end
    
  def contruct_urls
    %w(zoo playground).each do |r|
      [nil, "xml", "json", "yaml", "rob"].each do |fmt|
        yield r, fmt
      end
    end
  end
  
  def string_to_hash(string, format)
    case format
    when :json, :js
      JSON.parse(string)
    end
  end  
  
  describe "OPTIONS index" do
    
    before(:all) do
      @zoo = {  
        "methods" => %w(GET),
        "path"    => "/zoo",
        "fields"  => [{"id" => "Integer"},{"name" => "String"},{"city" => "String"},{"lat" => "String"},{"long" => "String"}],
        "resource_name" => "zoo"
      }
      @cats = {
        "methods" => %w(DELETE GET OPTIONS POST PUT),
        "path"    => "/cats",
        "fields"  => [{"id"                 => "Integer"},
                      {"breed"              => "String"},
                      {"dob"                => "Date"},
                      {"number_of_kittens"  => "Integer"},
                      {"mass"               => "Float"},
                      {"alive"              => "TrueClass"}],
        "resource_name" => "cats"
      }
      @people = {
        "methods" => %w(DELETE GET OPTIONS POST PUT),
         "path"    =>"/people",
         "fields"  => [{"id"   => "Integer"},
                       {"name" => "String"},
                       {"age"  => "Integer"},
                       {"dob"  => "DateTime"}],
        "resource_name" => "people"
      }
      @raw = { "zoo" => @zoo, "cats" => @cats, "people"  => @people }
      @zoo_json     = JSON.generate(@zoo)
      @cats_json    = JSON.generate(@cats)
      @people_json  = JSON.generate(@people)
      @total_json   = JSON.generate(@raw)            
    end
    
    describe "routes" do
      it "should route to the options method from root" do
        result = request_to("/rest", :options)
        result[:controller].should == "rest"
        result[:action].should == "options"
      end
      
      it "should route to #options with a /" do
        result = request_to("/rest/", :options)
        result[:controller].should == "rest"
        result[:action].should == "options"
      end
      
      it "should route to #options with a resource" do
        result = request_to("/rest/zoo", :options)
        result[:controller].should == "rest"
        result[:action].should == "options"
      end
      
      it "should error on an OPTIONS request to a member resource" do
        lambda do
          result = request_to("/rest/zoo/1", :options)
        end      
      end
    end
    
    describe "format payloads" do
      [:json].each do |fmt|
        it "should return the #{fmt} payload for all resources" do
          c = dispatch_to(MerbRestServer::Rest, :options, :format => fmt)
          string_to_hash(c.body, fmt).should == @raw
        end
    
        it "should return the #{fmt} payload for the zoo resource" do
          c = dispatch_to(MerbRestServer::Rest, :options, :resource => "zoo", :format => fmt)
          string_to_hash(c.body, fmt).should == @zoo
        end
      
        it "should return th #{fmt} payload for the people resource" do
          c = dispatch_to(MerbRestServer::Rest, :options, :resource => "people", :format => fmt)
          string_to_hash(c.body, fmt).should == @people
        end
      
        it "should return the #{fmt} payload for the cats resource" do
          c = dispatch_to(MerbRestServer::Rest, :options, :resource => "cats", :format => fmt)
          string_to_hash(c.body, fmt).should == @cats
        end
      end    
    end # format payloads   
    
    it "should raise a NotFound if a resource is requested that does not exist" do
      lambda do
        dispatch_to(MerbRestServer::Rest, :options, :resource => "not_real", :format => :json)
      end.should raise_error(Merb::Controller::NotFound)
    end
    
  end

  describe "GET index" do

    describe "routes" do    
      it "should raise on a get for the root" do
        lambda do
          request_to("/rest", :get)
        end
      end

      it "should route path/<resource> to #index" do
        contruct_urls do |r, fmt|
          ["/rest/#{r}#{fmt.blank? ? "" : ".#{fmt}"}"].each do |url|
            result = request_to(url)
            result[:controller].should == "rest"
            result[:action].should == "index"
            result[:resource].should == r
            result[:format].should == fmt
            result[:id].should be_nil
          end
        end
      end

      it "sshould route path/<resource>/ to #index}" do
        contruct_urls do |r, fmt|
          ["/rest/#{r}#{fmt.blank? ? "" : ".#{fmt}"}/"].each do |url|
            result = request_to(url)
            result[:controller].should == "rest"
            result[:action].should == "index"
            result[:resource].should == r
            result[:format].should == fmt
            result[:id].should be_nil
          end
        end
      end

      it "should route a path to #get" do
        contruct_urls do |r, fmt|
          ["/rest/#{r}/42#{fmt.blank? ? "" : ".#{fmt}"}"].each do |url|
            result = request_to(url)
            result[:controller].should == "rest"
            result[:action].should == "get"
            result[:resource].should == r
            result[:format].should == fmt
            result[:id].should == "42"
          end
        end
      end
    end
    
    describe "get" do
      
      def comp(params)
        MerbRestServer::CommandProcessor.new(params)
      end
      
      describe "collections" do
        it "should get all the people in xml" do
          cp = comp(:resource => "people")
          cp.all
          result = get("/rest/people.xml")
          result.body.should == cp.to_xml
        end
      
        it "should get all the cats" do
          cp = comp(:resource => "cats")
          cp.all
          result = get("/rest/cats.json")
          result.body.should == cp.to_json
        end
      
        it "should limit it to one cat" do
          expected = Cat.all(:limit => 1)
          cp = comp(:resource => "cats", :limit => 1)
          cp.all
          result = get("/rest/cats.json", :limit => 1)
          result.assigns(:command_processor).results.should == expected
          result.body.should == cp.to_json
        end
      
        it "should order the cats" do
          expected = Cat.all(:limit => 5, :order => [:breed.asc])
          cp = comp(:resource => "cats", :order => ["breed"], :limit => "5")
          cp.all
          result = get("/rest/cats.xml", :limit => 5, :order => [:breed])
          result.body.should == cp.to_xml
          result.assigns(:command_processor).results.should == expected
        end
        
        it "should order the cats in the reverse order" do
          expected = Cat.all(:limit => 5, :order => [:breed.desc])
          cp = comp(:resource => "cats", :order => ["breed.desc"], :limit => "5")
          cp.all
          result = get("/rest/cats.xml", :limit => 5, :order => ["breed.desc"])
          result.body.should == cp.to_xml
          result.assigns(:command_processor).results.should == expected
        end
        
        it "should order the cats when not in an array" do
          expected = Cat.all(:order => [:breed.desc])
          cp = comp(:resource => "cats", :order => "breed.desc")
          cp.all
          result = get("/rest/cats.xml", :order => "breed.desc")
          result.body.should == cp.to_xml
          result.assigns(:command_processor).results.should == expected
        end
        
        it "should order by multiple fields" do
          expected = Cat.all(:order => [:breed.desc, :dob.asc])
          cp = comp(:resource => "cats", :order => ["breed.desc", "dob.asc"])
          cp.all
          result = get("/rest/cats.xml", :order => ["breed.desc", "dob.asc"])
          result.assigns(:command_processor).results.should == expected
          result.body.should == cp.to_xml
        end
        
        it "should return an empty array if there are no cats found" do
          cat = Cat.all(:breed => ("a" * 59))
          cat.should have(0).items
          cp = comp(:resource => "cats", :q => {"breed" => ("a" * 59)})
          cp.all
          cp.results.should be_empty
          result = get("/rest/cats.xml", :q => {"breed" => ("a" * 59)})
          result.body.should == cp.to_xml
          result.assigns(:command_processor).results.should == cat
        end
      end
      
      describe "specific members" do
      
        it "should get a specific person" do
          person = Person.first
          cp = comp(:resource => "people", :id => person.id )
          cp.first
          result = get("/rest/people/#{person.id}.xml")
          result.body.should == cp.to_xml
          result.assigns(:command_processor).results.should == person
        end
      
        it "should return a 404 if the person is not found" do
          Person.first(:id => 999).should be_nil
          lambda do
            result = get("/rest/people/999.json") 
          end.should raise_error(Merb::Controller::NotFound)
        end
      end
    end
  
  #   describe "plain index" do
  #     before do
  #       @controller = get("/rest/foo", {}, :http_accept => "application/json")
  #     end
  #   
  #     it "routes GET /rest/foo to Rest#index" do
  #       @controller.action_name.should == "index"
  #     end
  #   
  #     it "returns all of the resources" do
  #       @controller.body.should == Foo.all.to_json
  #     end
  #   end
  #   
  #   describe "index with query parameters" do
  #     it "provides the objects that match ids" do
  #       controller = get("/rest/foo", {:id => "1,2"}, :http_accept => "application/json")
  #       controller.body.should == Foo.all(:id => [1,2]).to_json
  #     end
  #     
  #     it "provides the objects that match other params" do
  #       controller = get("/rest/foo", {:name => "Mock1"}, :http_accept => "application/json")
  #       controller.body.should == Foo.all(:name => "Mock1").to_json
  #     end
  #     
  #     it "supports providing the type of query" do
  #       controller = get("/rest/foo", {:name => "Mock%", :query_type => "like"}, :http_accept => "application/json")
  #       controller.body.should == Foo.all(:name.like => "Mock%").to_json
  #     end
  #   end
  end
  
    it "should get all the "
  # describe "OPTIONS on a resource" do
  #   describe "when the resource exists" do
  #     it "returns back the schema in JSON form" do
  #       @controller = request("/rest/foo/1", {}, :http_accept => "application/json", :request_method => "OPTIONS")
  #       @controller.body.should == Foo.properties.inject({}) {|a,x| a[x.name] = x.type; a }.to_json        
  #     end
  #   end
  # end
  # 
  # describe "GET" do
  #   describe "when the resource exists" do
  #     before do
  #       @controller = get("/rest/foo/1", {}, :http_accept => "application/json")
  #     end
  #   
  #     it "routes GET /rest/foo/1 to Rest#show :id => 1" do
  #       @controller.action_name.should == "get"
  #       @controller.params[:id].should == "1"
  #     end
  #   
  #     it "assigns the object as Foo.get!(1)" do
  #       @controller.assigns(:object).should == Foo.get!(1)
  #     end
  #   
  #     it "returns the object's attributes as JSON" do
  #       @controller.body.should == Foo.get!(1).to_json
  #     end
  #   end
  #   
  #   describe "when the resource doesn't exist" do
  #     it "returns a 404" do
  #       @controller = get("/rest/foo/10", {}, :http_accept => "application/json")
  #       @controller.status.should == 404
  #     end
  #   end
  # end
  # 
  describe "POST" do
    
    describe "routes" do    
      it "should raise on a post for the root" do
        lambda do
          request_to("/rest", :post)
        end
      end

      it "should route path/<resource> to #index" do
        contruct_urls do |r, fmt|
          ["/rest/#{r}#{fmt.blank? ? "" : ".#{fmt}"}"].each do |url|
            result = request_to(url, :post)
            result[:controller].should == "rest"
            result[:action].should == "post"
            result[:resource].should == r
            result[:format].should == fmt
            result[:id].should be_nil
          end
        end
      end

      it "sshould route path/<resource>/ to #index}" do
        contruct_urls do |r, fmt|
          ["/rest/#{r}#{fmt.blank? ? "" : ".#{fmt}"}/"].each do |url|
            result = request_to(url, :post)
            result[:controller].should == "rest"
            result[:action].should == "post"
            result[:resource].should == r
            result[:format].should == fmt
            result[:id].should be_nil
          end
        end
      end
    end
  #   it "routes POST /rest/foo/1 to Rest#update :id => 1" do
  #     controller = post("/rest/foo/1")
  #     controller.action_name.should == "post"
  #     controller.params[:id].should == "1"
  #   end    
  end
  # 
  describe "PUT" do
    
    describe "routes" do    
      it "should raise on a put for the root" do
        lambda do
          request_to("/rest", :put)
        end
      end

      it "should route path/<resource> to #index" do
        contruct_urls do |r, fmt|
          ["/rest/#{r}#{fmt.blank? ? "" : ".#{fmt}"}"].each do |url|
            result = request_to(url, :put)
            result[:controller].should == "rest"
            result[:action].should == "put"
            result[:resource].should == r
            result[:format].should == fmt
            result[:id].should be_nil
          end
        end
      end

      it "sshould route path/<resource>/ to #index}" do
        contruct_urls do |r, fmt|
          ["/rest/#{r}#{fmt.blank? ? "" : ".#{fmt}"}/"].each do |url|
            result = request_to(url, :put)
            result[:controller].should == "rest"
            result[:action].should == "put"
            result[:resource].should == r
            result[:format].should == fmt
            result[:id].should be_nil
          end
        end
      end

      it "should route a path to #put" do
        contruct_urls do |r, fmt|
          ["/rest/#{r}/42#{fmt.blank? ? "" : ".#{fmt}"}"].each do |url|
            result = request_to(url, :put)
            result[:controller].should == "rest"
            result[:action].should == "put"
            result[:resource].should == r
            result[:format].should == fmt
            result[:id].should == "42"
          end
        end
      end
    end
  #   it "routes PUT /rest/foo/1 to Rest#update :id => 1" do
  #     controller = put("/rest/foo/1")
  #     controller.action_name.should == "put"
  #     controller.params[:id].should == "1"
  #   end    
  end
  # 
  describe "DELETE" do 
    
    describe "routes" do    
      it "should raise on a delete for the root" do
        lambda do
          request_to("/rest", :delete)
        end
      end

      it "should route path/<resource> to #index" do
        contruct_urls do |r, fmt|
          ["/rest/#{r}#{fmt.blank? ? "" : ".#{fmt}"}"].each do |url|
            result = request_to(url, :delete)
            result[:controller].should == "rest"
            result[:action].should == "delete"
            result[:resource].should == r
            result[:format].should == fmt
            result[:id].should be_nil
          end
        end
      end

      it "sshould route path/<resource>/ to #index}" do
        contruct_urls do |r, fmt|
          ["/rest/#{r}#{fmt.blank? ? "" : ".#{fmt}"}/"].each do |url|
            result = request_to(url, :delete)
            result[:controller].should == "rest"
            result[:action].should == "delete"
            result[:resource].should == r
            result[:format].should == fmt
            result[:id].should be_nil
          end
        end
      end

      it "should route a path to #delete" do
        contruct_urls do |r, fmt|
          ["/rest/#{r}/42#{fmt.blank? ? "" : ".#{fmt}"}"].each do |url|
            result = request_to(url, :delete)
            result[:controller].should == "rest"
            result[:action].should == "delete"
            result[:resource].should == r
            result[:format].should == fmt
            result[:id].should == "42"
          end
        end
      end
    end
  #   it "routes DELETE /rest/foo/1 to Rest#update :id => 1" do
  #     controller = delete("/rest/foo/1")
  #     controller.action_name.should == "delete"
  #     controller.params[:id].should == "1"
  #   end
  end
  # 
  # it "should have access to the slice module" do
  #   controller = dispatch_to(MerbRestServer::Rest, :index)
  #   controller.slice.should == MerbRestServer
  #   controller.slice.should == MerbRestServer::Rest.slice
  # end
  # 
  # it "should have an index action" do
  #   controller = dispatch_to(MerbRestServer::Rest, :index)
  #   controller.status.should == 200
  #   controller.body.should contain('MerbRestServer')
  # end
  # 
  # it "should work with the default route" do
  #   controller = get("/merb_rest_server/main/index")
  #   controller.should be_kind_of(MerbRestServer::Rest)
  #   controller.action_name.should == 'index'
  # end
  # 
  # it "should work with the example named route" do
  #   controller = get("/merb_rest_server/index.html")
  #   controller.should be_kind_of(MerbRestServer::Main)
  #   controller.action_name.should == 'index'
  # end
  # 
  # it "should have routes in MerbRestServer.routes" do
  #   MerbRestServer.routes.should_not be_empty
  # end
  # 
  # it "should have a slice_url helper method for slice-specific routes" do
  #   controller = dispatch_to(MerbRestServer::Main, 'index')
  #   controller.slice_url(:action => 'show', :format => 'html').should == "/merb_rest_server/main/show.html"
  #   controller.slice_url(:merb_rest_server_index, :format => 'html').should == "/merb_rest_server/index.html"
  # end
  # 
  # it "should have helper methods for dealing with public paths" do
  #   controller = dispatch_to(MerbRestServer::Main, :index)
  #   controller.public_path_for(:image).should == "/slices/merb_rest_server/images"
  #   controller.public_path_for(:javascript).should == "/slices/merb_rest_server/javascripts"
  #   controller.public_path_for(:stylesheet).should == "/slices/merb_rest_server/stylesheets"
  # end
  # 
  # it "should have a slice-specific _template_root" do
  #   MerbRestServer::Main._template_root.should == MerbRestServer.dir_for(:view)
  #   MerbRestServer::Main._template_root.should == MerbRestServer::Application._template_root
  # end

end