require File.dirname(__FILE__) + '/../spec_helper'

describe MerbRestServer::CommandProcessor do
  
  before(:all) do
    Person.auto_migrate!
    
    MerbRestServer.resources.clear
    class RestPersonResource < MerbRestServer::RestResource
      resource_class Person
    end
  end
  
  before(:each) do
    10.of {Person.generate}
  end
  
  after(:each) do
    Person.all.destroy!
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
    cp.buggeroff
    .should == YAML.dump(cp.to_hash)
  end
    
end