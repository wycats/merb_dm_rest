require File.dirname(__FILE__) + '/../spec_helper'

describe "MerbRestServer::Rest (controller)" do
  
  # Feel free to remove the specs below
  
  before :all do
    Merb::Router.reset!
    Merb::Router.prepare { add_slice(:merb_rest_server, :path_prefix => "rest") }
    Merb::Authentication.default_strategy_order.clear
    
    class Capturer
      cattr_accessor :captures
      @@captures = []
    end
    
    class TestAuth < Merb::Authentication::Strategy
      def run!
        Capturer.captures << TestAuth
        "in" unless params[:run_through]
      end
    end
    
    class TestAuth2 < Merb::Authentication::Strategy
      def run!
        Capturer.captures << TestAuth2
        nil
      end
    end
        
    
    class SingleAuthenticatedZoo < MerbRestServer::RestResource
      resource_class Zoo
      resource_name "auth-single-zoo"
      authenticate_with TestAuth
    end
    
    class DefaultAuthenticatedZoo < MerbRestServer::RestResource
      resource_class Zoo
      resource_name "auth-default-zoo"
      authenticate_with :default
    end
    
    class NoneAuthenticatedZoo < MerbRestServer::RestResource
      resource_class Zoo
      resource_name "auth-none-zoo"
      authenticate_with :none
    end
        
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

    Merb::Authentication.default_strategy_order.clear
    Object.class_eval do
      remove_const(:TestAuth) if defined?(TestAuth)
      remove_const(:TestAuth2) if defined?(TestAuth2)
    end
  end

  require File.dirname(__FILE__) + '/../spec_helper'    
  
  before(:all) do
    Person.auto_migrate!
    Cat.auto_migrate!
    Zoo.auto_migrate!
    (0..100).of { Person.generate }   
    (0..100).of { Cat.generate}
  end
  
  
  before(:each) do
    Capturer.captures.clear
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
        result[:controller].should == "merb_rest_server/rest"
        result[:action].should == "options"
      end
      
      it "should route to #options with a /" do
        result = request_to("/rest/", :options)
        result[:controller].should == "merb_rest_server/rest"
        result[:action].should == "options"
      end
      
      it "should route to #options with a resource" do
        result = request_to("/rest/zoo", :options)
        result[:controller].should == "merb_rest_server/rest"
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
          c = request("/rest/index.#{fmt}", :method => "options")
          string_to_hash(c.body.to_s, fmt) == MerbRestServer.resource_options
        end
    
        it "should return the #{fmt} payload for the zoo resource" do
          c = request("/rest/zoo.#{fmt}", :method => "options")
          string_to_hash(c.body.to_s, fmt).should == @zoo
        end
      
        it "should return th #{fmt} payload for the people resource" do
          c = request("/rest/people.#{fmt}", :method =>"options")
          string_to_hash(c.body.to_s, fmt).should == @people
        end
      
        it "should return the #{fmt} payload for the cats resource" do
          c = request("/rest/cats.#{fmt}", :method => "options")
          string_to_hash(c.body.to_s, fmt).should == @cats
        end
      end    
    end # format payloads   
    
    it "should raise a NotFound if a resource is requested that does not exist" do
      r = request("/rest/not_real.json", :method => "options")
      r.status.should == 404
    end
    
    describe "Authentication" do
      
      it "should be authenticated with the default strategies" do
        r = request("/rest/auth-default-zoo", :method => "options", :params => {:run_through => true})
        Capturer.captures.should == [TestAuth, TestAuth2]
      end
      
      it "should be authenticated with a single strategy" do
        r = request("/rest/auth-single-zoo", :method => "options")
        Capturer.captures.should == [TestAuth]
      end
      
      it "should be authenticated with no strategies" do
        r = request("/rest/auth-none-zoo", :method => "options")
        Capturer.captures.should be_blank
      end
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
            result[:controller].should == "merb_rest_server/rest"
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
            result[:controller].should == "merb_rest_server/rest"
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
            result[:controller].should == "merb_rest_server/rest"
            result[:action].should == "get"
            result[:resource].should == r
            result[:format].should == fmt
            result[:id].should == "42"
          end
        end
      end
    end
    
    describe "get" do
      
      before(:each) do
        @request = fake_request
      end
      
      def comp(params)
        MerbRestServer::CommandProcessor.new(params)
      end
      
      describe "collections" do
        it "should get all the people in xml" do
          @request.params[:resource] = "people"
          cp = comp(@request)
          cp.all
          result = request("/rest/people.xml")
          result.body.to_s.should == cp.to_xml
        end
      
        it "should get all the cats" do
          @request.params[:resource] = "cats"
          cp = comp(@request)
          cp.all
          result = request("/rest/cats.json")
          result.body.to_s.should == cp.to_json
        end
      
        it "should limit it to one cat" do
          expected = Cat.all(:limit => 1)
          @request.params.merge!(:resource => "cats", :limit => 1)
          cp = comp(@request)
          cp.all
          result = request("/rest/cats.json", :params => {:limit => 1})
          JSON.parse(result.body.to_s).should == JSON.parse(cp.to_json)
          result.body.to_s.should_not be_blank
        end
      
        it "should order the cats" do
          expected = Cat.all(:limit => 5, :order => [:breed.asc])
          @request.params.merge! :resource => "cats", :order => ["breed"], :limit => "5"
          cp = comp(@request)
          cp.all
          result = request("/rest/cats.xml", :params => {:limit => 5, :order => [:breed]})
          result.body.to_s.should == cp.to_xml
          result.body.to_s.should_not be_blank
        end
      
        it "should order the cats in the reverse order" do
          expected = Cat.all(:limit => 5, :order => [:breed.desc])
          @request.params.merge! :resource => "cats", :order => ["breed.desc"], :limit => "5"
          cp = comp(@request)
          cp.all
          result = request("/rest/cats.xml", :params => {:limit => 5, :order => ["breed.desc"]})
          result.body.to_s.should == cp.to_xml
          result.body.to_s.should_not be_blank
        end
        
        it "should order the cats when not in an array" do
          expected = Cat.all(:order => [:breed.desc])
          @request.params.merge! :resource => "cats", :order => "breed.desc"
          cp = comp(@request)
          cp.all
          result = request("/rest/cats.xml", :params => {:order => "breed.desc"})
          result.body.to_s.should == cp.to_xml
          result.body.to_s.should_not be_blank
        end
        
        it "should order by multiple fields" do
          expected = Cat.all(:order => [:breed.desc, :dob.asc])
          @request.params.merge! :resource => "cats", :order => ["breed.desc", "dob.asc"]
          cp = comp(@request)
          cp.all
          result = request("/rest/cats.xml", :params => {:order => ["breed.desc", "dob.asc"]})
          result.body.should == cp.to_xml
          result.body.to_s.should_not be_blank
        end
        
        it "should return an empty array if there are no cats found" do
          cat = Cat.all(:breed => ("a" * 59))
          cat.should have(0).items
          @request.params.merge! :resource => "cats", :q => {"breed" => ("a" * 59)}
          cp = comp(@request)
          cp.all
          cp.results.should be_empty
          result = request("/rest/cats.xml", :params => {:q => {"breed" => ("a" * 59)}})
          result.body.should == cp.to_xml
          result.body.should_not be_blank
        end
      end
      
      describe "specific members" do
      
        it "should get a specific person" do
          person = Person.first
          request = fake_request
          request.params.merge! :resource => "people", :id => person.id 
          cp = comp(request)
          cp.first
          result = request("/rest/people/#{person.id}.xml")
          result.body.to_s.should == cp.to_xml
          result.body.to_s.should_not be_blank
        end
      
        it "should return a 404 if the person is not found" do
          Person.first(:id => 999).should be_nil
          result = request("/rest/people/999.json") 
          result.status.should == Merb::Controller::NotFound.status
        end
      end
    end
  
  end

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
            result[:controller].should == "merb_rest_server/rest"
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
            result[:controller].should == "merb_rest_server/rest"
            result[:action].should == "post"
            result[:resource].should == r
            result[:format].should == fmt
            result[:id].should be_nil
          end
        end
      end
    end

    it "should create a new cat" do
      lambda do
        r = request("/rest/cats", :method => "post", :params => {:cats => {:breed => "A Breed", :dob => DateTime.now - 6, :number_of_kittens => 0}})
        r.status.should == 201
      end.should change(Cat, :count).by(1)
    end
    
    it "should create a new person" do
      lambda do
        r = request("/rest/people", :method => "post", :params => {:people => {:name => "Fred"}})
        r.status.should == 201
      end.should change(Person, :count).by(1)
    end
    
    it "should raise a 405 if the method is not allowed for this resource" do
      r = request("/rest/zoo", :method => "post", :params => {:zoo => {:name =>"my zoo", :city => "A city"}})
      r.status.should == Merb::Controller::MethodNotAllowed.status
    end
    
    it "should not create a resource if the POST method is not allowed" do
      lambda do
        r = request("/rest/zoo", :method => "post", :params => {:zoo => {:name => "my zoo", :city => "A city"}})
        r.status.should == Merb::Controller::MethodNotAllowed.status
      end.should_not change(Zoo, :count)     
    end
    
    it "should raise a 403 if unable to create the item" do
      lambda do
        r = request("/rest/people", :method => "post", :params => {:people => {:age => 5}})
        r.status.should == Merb::Controller::Forbidden.status
      end.should_not change(Person, :count)
    end
  end
  # 
  describe "PUT" do
    
    before(:all) do
      Person.all.destroy!
      Cat.all.destroy!
    end
    
    before(:each) do
      10.of {Person.generate}
      12.of {Cat.generate}
    end
    
    after(:each) do
      Person.all.destroy!
      Cat.all.destroy!
    end
    
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
            result[:controller].should == "merb_rest_server/rest"
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
            result[:controller].should == "merb_rest_server/rest"
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
            result[:controller].should == "merb_rest_server/rest"
            result[:action].should == "put"
            result[:resource].should == r
            result[:format].should == fmt
            result[:id].should == "42"
          end
        end
      end
    end

    describe "collection updates" do
      it "should update all people to name 'bill'" do
        pending
        request("/people", :method => :put, :params => {:person => {:name => "bill"}})
        Person.all.each{|p| p.name.should == "bill"}
      end
      
      it "should only update a single users name" do
        pending
      end
      
      it "should raise a MethodNotAllowed if the method has not been allowed for this resource" do
        pending
      end
      
      it "should return the affected collection" do
        pending 
      end
    end
    
    describe "member updates" do
      it "should update and individual only to have the name 'bill'" do
        pending
      end
      
      it "should raise a MethodNotAllowed if the method has not been allowed for the resource" do
        pending
      end
      
      it "should raise a NotFound if the specified resource cannot be found" do
        pending
      end
      
      it "should return the affected item" do
        pending
      end
      
    end
    
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
            result[:controller].should == "merb_rest_server/rest"
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
            result[:controller].should == "merb_rest_server/rest"
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
            result[:controller].should == "merb_rest_server/rest"
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
end