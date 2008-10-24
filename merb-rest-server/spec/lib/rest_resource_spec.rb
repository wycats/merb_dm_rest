require File.dirname(__FILE__) + '/../spec_helper'

describe "MerbRestServer::RestResource" do
  
  before(:all) do
    @rest_methods = ["OPTIONS", "GET", "PUT", "POST", "DELETE"].sort
    
    class PersonRestResource < MerbRestServer::RestResource
      resource_class Person
    end
    
  end
  
  before(:each) do
    @rr = PersonRestResource
  end
  
  after(:each) do
    PersonRestResource.reset_rest_methods!
    PersonRestResource.repository repository(:default)
  end
  
  describe "interface" do
    
    it{@rr.should respond_to(:rest_methods)}
    it{@rr.should_not respond_to(:rest_methods=)}
    it{@rr.should respond_to(:resource_name)}
    it{@rr.should respond_to(:resource_class)}
    it{@rr.should respond_to(:fields)}
    it{@rr.should respond_to(:expose_fields)}
    it{@rr.should respond_to(:to_json)}
    it{@rr.should respond_to(:to_yaml)}
    
  end # interface
  
  describe "rest_methods" do
    it "should be an array of all methods by default" do
      @rr.rest_methods.sort.should == @rest_methods
    end
    it "should allow a user to specify the rest methods on initialization" do
      class APersonResource < MerbRestServer::RestResource
        resource_class Person
        rest_methods  %w(POST GET)
      end
      
      APersonResource.rest_methods.should == ["POST", "GET"]
    end
    
    it "should allow the rest_methods to be cleared" do
      @rr.rest_methods.should_not be_empty
      @rr.rest_methods.clear
      @rr.rest_methods.should be_empty
    end


  end

  describe "resource name" do
    
    it "should use the class's default name as the resource name" do
      result = Person.storage_name
      @rr.resource_name.should == result
    end
    
    it "should allow you to set the resource name" do
      @rr.resource_name "persona"
      @rr.resource_name.should == "persona"
    end
    
    it "should allow you to set the resource name with a symbol" do
      @rr.resource_name :personne
      @rr.resource_name.should == "personne"
    end
    
    it "should allow you to set the repository" do
      @rr.repository = repository(:tester)
    end
    
    it "should raise an error if the repository isn't a DataMapper::Repository" do
      lambda do
        @rr.repository :tester
      end.should raise_error(ArgumentError)
    end
    
    it "should not allow you to set the resource name to anything but a string" do
      [["fake"], {:not => "right"}, 341].each do |rn|
        lambda do
          @rr.resource_name rn
        end.should raise_error(ArgumentError)
      end
    end
  end

  describe "fields" do
    it "should select all the fields by default" do
      @rr.fields.should == [{:id => Integer}, {:name => String}, {:age => Integer}, {:dob => DateTime}]
    end
    
    it "should select all fields in the repository by default" do
      class PersonTesterResource < MerbRestServer::RestResource
        repository DataMapper.repository(:tester)
        resource_class Person
      end
      
      expected = [ {:id    => Integer}, 
                   {:name  => String}, 
                   {:age   => Integer}, 
                   {:dob   => DateTime}, 
                   {:nick  => String}]
      results = PersonTesterResource.fields
      expected.each{|e| results.should include(e); results.delete(e)}
      results.should be_empty
    end
    
    it "should allow the fields to be set manually" do
      @rr.expose_fields(:id, :name, :age)
      @rr.fields.should == [{:id => Integer}, {:name => String}, {:age => Integer}]
    end
    
    it "should raise an error if a field does not exist on the model" do
      lambda do
        @rr.expose_fields(:id, :does_not_exist)
      end.should raise_error(ArgumentError)      
    end
    
  end

  it "should output the options for the resource" do
    PersonRestResource.options.should == {
                                              :methods        =>  ["DELETE", "GET", "OPTIONS", "POST", "PUT"], 
                                              :resource_name  =>  "people", 
                                              :path           =>  "/people", 
                                              :fields         =>  [{:id=>Integer}, {:name=>String}, {:age=>Integer}, {:dob=>DateTime}]
                                            }
  end
  
  it "should take into account the other methods and fields" do
    class APersonResource < MerbRestServer::RestResource
      resource_class Person
      resource_name "another_person"
      rest_methods  %w(POST GET)
      expose_fields :id, :name, :age
    end
    
    APersonResource.options.should == {
                                        :methods        =>  ["POST", "GET"], 
                                        :resource_name  =>  "another_person", 
                                        :path           =>  "/another_person", 
                                        :fields         =>  [{:id=>Integer}, {:name=>String}, {:age=>Integer}]
                                      }
    
  end

  describe "default conditions" do
    
    before(:each) do
      Object.class_eval{ remove_const("PersonRestResource") if defined?(PersonRestResource)}
      class PersonRestResource < MerbRestServer::RestResource
        resource_class Person
      end
    end
    
    after(:all) do
      Object.class_eval{ remove_const("PersonRestResource") if defined?(PersonRestResource)}
    end
    
    it "should allow default conditions to be set" do
      PersonRestResource.default_conditions {}
    end
    
    it "should provide access to the custom conditions" do
      PersonRestResource.default_conditions :name => "bar"
      PersonRestResource.default_conditions.should == {:name => "bar"}
    end
    
    it "should allow a default condition to be a proc" do
      l = lambda{"foo"}
      PersonRestResource.default_conditions :name => l
      PersonRestResource.default_conditions.should == {:name => l}
    end
    
  end
  
  describe "custom finder method" do
    
    before(:each) do
      Object.class_eval{ remove_const(:PersonRestResource) if defined?(PersonRestResource)}
      class PersonRestResource < MerbRestServer::RestResource
        resource_class Person
        collection_finder :all
        member_finder :first
      end
    end
    
    after(:all) do
      Object.class_eval{ remove_const(:PersonRestResource) if defined?(PersonRestResource)}
    end
    
    describe "collection finder" do
      it "should be :all by default" do
        PersonRestResource.collection_finder.should == :all
      end
      
      it "should allow a custom finder method to be set" do
        PersonRestResource.collection_finder :my_custom_collection_finder
      end

      it "should provide access to the custom finder" do
        PersonRestResource.collection_finder :my_custom_collection_finder
        PersonRestResource.collection_finder.should == :my_custom_collection_finder
      end

      it "should allow a string for the cutsom finder method" do
        PersonRestResource.collection_finder "my_custom_collection_finder"
        PersonRestResource.collection_finder.should == :my_custom_collection_finder
      end

      it "should allow a proc to be given for a custom finder method" do
        lambda do
          PersonRestResource.collection_finder { |params| "I've got access to the params hash" }
        end.should_not raise_error
      end

      it "should fail for other object types" do
        [Object.new, DateTime.now, Object].each do |thing|
          lambda do
            PersonRestResource.collection_finder = thing
          end.should raise_error
        end
      end
    end
    
    describe "member finder" do
      it "should be :first by default" do
        PersonRestResource.member_finder.should == :first
      end
      
      it "should allow a custom finder method to be set" do
        PersonRestResource.member_finder :my_custom_member_finder
      end

      it "should provide access to the custom finder" do
        PersonRestResource.member_finder :my_custom_member_finder
        PersonRestResource.member_finder.should == :my_custom_member_finder
      end

      it "should allow a string for the cutsom finder method" do
        PersonRestResource.member_finder "my_custom_member_finder"
        PersonRestResource.member_finder.should == :my_custom_member_finder
      end

      it "should allow a proc to be given for a custom finder method" do
        lambda do
          PersonRestResource.member_finder {|params| "I've got access to the params hash" }
        end.should_not raise_error
      end

      it "should fail for other object types" do
        [Object.new, DateTime.now, Object].each do |thing|
          lambda do
              PersonRestResource.member_finder = thing
          end.should raise_error
        end
      end
    end
  end
  
  describe "merb-auth integration" do
    
    before(:each) do
      Object.class_eval{ remove_const("Person2RestResource") if defined?(Person2RestResource)}
      class Person2RestResource < MerbRestServer::RestResource
        resource_class Person
      end
    end
    
    after(:all) do
      Object.class_eval{ remove_const("Person2RestResource") if defined?(Person2RestResource)}
    end
    
    it "should allow you to specify authentication strategeis" do
      Person2RestResource.authenticate_with "OpenID", "BasicAuth"
      Person2RestResource.authenticate_with.should == %w(OpenID BasicAuth)
    end    
    
    it "should allow you to set the strategy to :default" do
      Person2RestResource.authenticate_with :default
      Person2RestResource.authenticate_with.should == :default
    end
    
    it "should allow you to set the strategy to :none" do
      Person2RestResource.authenticate_with :none
      Person2RestResource.authenticate_with.should == :none
    end
  end
end