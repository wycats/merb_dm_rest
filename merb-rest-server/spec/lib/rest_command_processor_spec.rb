require File.dirname(__FILE__) + '/../spec_helper'

describe MerbRestServer::CommandProcessor do
  
  before(:all) do
    Person.auto_migrate!
    
    MerbRestServer.resources.clear
  end
  
  before(:each) do
    Object.class_eval{ remove_const("RestPersonResource") if defined?(RestPersonResource)}
    10.of {Person.generate}
    
    class RestPersonResource < MerbRestServer::RestResource
      resource_class Person
    end
  end
  
  after(:each) do
    Person.all.destroy!
  end
  
  after(:all) do
    Object.class_eval{ remove_const("RestPersonResource") if defined?(RestPersonResource)}
  end
  
  def comp(params)
    MerbRestServer::CommandProcessor.new(params)
  end
  
  it "should setup the spec correctly" do
    Person.all.should have(10).items
  end
  
  it "should take a params hash and get all matches" do
    params = {:resource => "people"}
    cp = comp(params)
    cp.all
    cp.results.should == Person.all    
  end
  
  it "should take a params hash and get the first match" do
    params = {:resource => "people"}
    cp = comp(params)
    cp.first.should == Person.first
    cp.results.should == Person.first
  end

  it "should convert the results to a hash when a single object" do
    params = {:resource => "people"}
    person = Person.first
    expected = {}
    person.attributes.each do |name, value|
      expected[name] = value
    end
    cp = comp(params)
    cp.first
    cp.to_hash.should == expected
  end
  
  it "should convert the restults to a hash when an collection of objects" do
    params = {:resource => "people"}
    people = Person.all
    expected = {"people" => []}
    people.each do |p|
      tmp = {}
      p.attributes.each do |n,v|
        tmp[n] = v
      end
      expected["people"] << tmp
    end
    cp= comp(params)
    cp.all
    cp.to_hash.should == expected
  end
  
  it "should convert the results to xml" do
    cp = comp(:resource => "people")
    cp.all
    cp.to_xml.should ==  Merb::Rest::Formats::Xml.encode(cp.to_hash)    
  end
  
  it "should convert the results to json" do
    cp = comp(:resource => "people")
    cp.all
    cp.to_json.should == JSON.generate(cp.to_hash)
  end
  
  it "should convert the results to marshalled ruby" do
    cp = comp(:resource => "people")    
    cp.all
    cp.to_rb.should == Marshal.dump(cp.to_hash)
  end
  
  it "should convert to yaml" do
    cp = comp(:resource => "people")
    cp.all
    cp.to_yaml.should == YAML.dump(cp.to_hash)
  end
    
  describe "default conditions" do
    
    before(:each) do
      Person.create(:name => "Fred",  :age => 42)
      Person.create(:name => "Wilma", :age => 25)
      Person.create(:name => "Homer", :age => 38)
      Person.create(:name => "Marge", :age => 30)
    end    
    
    it "should not affect direct access to the resource" do
      Person.all.size.should == Person.count
      Person.all.should have(14).items
    end
    
    it "should apply the default conditions to all" do
      RestPersonResource.default_conditions :name.like => "Hom%" 
      params = {:resource => "people"}
      cp = comp(params)
      cp.all
      cp.results.should == Person.all(:name.like => "Hom%")
    end
    
    it "should apply the default conditions to first" do
      RestPersonResource.default_conditions :name.like => "Hom%"
      params = {:resource => "people"}
      cp = comp(params)
      cp.first.should == Person.first(:name.like => "Hom%")
    end
      
  end
  
  describe "custom finder method" do
    
    before(:each) do
      params = {:resource => "people"}
      @cp = comp(params)
    end
    
    it "should use the custom finder method for collections" do
      Person.should_receive(:my_custom_collection_finder)
      RestPersonResource.collection_finder = :my_custom_collection_finder
      @cp.all
    end
    
    it "should use the custom finder method as a proc" do
      RestPersonResource.collection_finder = lambda{ |params| "In With The Params"}
      @cp.all.should == "In With The Params"
    end
    
    it "should use the custom finder method for members" do
      Person.should_receive(:my_custom_member_finder)
      RestPersonResource.member_finder = :my_custom_member_finder
      @cp.first
    end
    
    it "should use the custom finder method as a proc" do
      RestPersonResource.member_finder = lambda{ |params| "In With The Params"}
      @cp.first.should == "In With The Params"
    end
    
  end

end