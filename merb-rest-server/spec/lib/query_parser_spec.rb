require File.dirname(__FILE__) + '/../spec_helper'

describe MerbRestServer::QueryParser do
  
  before(:all) do
    QP = MerbRestServer::QueryParser
    class CatRestResource < MerbRestServer::RestResource
      resource_class Cat
      resource_name  "cats"
    end
    class PersonRestResource < MerbRestServer::RestResource
      resource_class Person
      resource_name  "people"
    end
    
    Cat.auto_migrate!
    Person.auto_migrate!
  end
  
  before(:each) do
    20.of {Cat.gen}
    10.of {Person.gen}
  end  
  
  after(:each) do
    Cat.all.destroy!
    Person.all.destroy!
  end
  
  it{QP.should respond_to(:parse)}
  
  it "should raise a Merb::Controller::NotFound exception if the resource is not registered" do
    lambda do
      QP.parse("does_not_exist", {})
    end.should raise_error(Merb::Controller::NotFound)
  end
  
  it "should return a query object for a given class" do
    QP.parse("cats", {}).should be_a_kind_of(DataMapper::Query)
  end
  
  it "should return all cats when there are no conditions specified" do
    Cat.all(QP.parse("cats", {})).should have(20).items
    Cat.all(QP.parse("cats", {})).should == Cat.all
  end
  
  it "should limit the cats" do
    Cat.all(QP.parse("cats", "limit" => "10")).should have(10).items
  end
  
  it "should limit the fields that are available to the query" do
    query = (QP.parse("cats", "fields" => ["breed", "number_of_kittens"]))
    query.fields.should have(2).items
    [:breed, :number_of_kittens].each do |param|
      query.fields.should include(Cat.properties[param])
    end
  end
  
  it "should set the offset if specified" do
    query = QP.parse("cats", "limit" => "3", "offset" => "2")
    query.limit.should == 3
    query.offset.should == 2
  end
  
  it "should typecast values from strings for the parameters"  
  it "should only allow fields that have been specified in the rest_resource"
  
  
end