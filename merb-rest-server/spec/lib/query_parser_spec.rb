require File.dirname(__FILE__) + '/../spec_helper'

describe MerbRestServer::QueryParser do
  
  before(:all) do
    QP = MerbRestServer::QueryParser unless defined?(QP)
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
  
  describe "typecasting" do
    
    it "should typecast a string" do
      q = QP.parse("people", "q" => {"name" => "fred"})
      q.conditions.should include([:eql, Person.properties[:name], "fred"])
    end
    
    it "should typecase an integer" do
      q = QP.parse("people", "q" => {"id" => "42"})
      q.conditions.should include([:eql, Person.properties[:id], 42])
    end
    
    it "should typecast a float" do
      q = QP.parse("cats", "q" => {"mass" => "1.23"})
      q.conditions.should include([:eql, Cat.properties[:mass], 1.23])
    end
    
    it "should typecast a boolean" do
      q = QP.parse("cats", "q" => {"alive" => "0"})
      q.conditions.should include([:eql, Cat.properties[:alive], false])
    end
    
    it "should typecast a DateTime" do
      date_time = DateTime.now
      df        = date_time.strftime("%Y%m%dT%H:%M:%S%Z")
      
      q = QP.parse("people", "q" => {"dob" => df})
      cond = q.conditions.first
      cond[2].to_s.should == date_time.to_s
    end
    
    it "should typecast a Date" do
      date = Date.today
      df   = date.strftime("%Y%m%dT%H:%M:%S%Z")
      q = QP.parse("cats", "q" => {"dob" => df })
      cond = q.conditions.first
      cond[2].should == Date.today
    end
        
    
  end
  
  it "should not allow a field that is not inclded in the properties" do
    class RestrictedPersonResrouce < MerbRestServer::RestResource
      resource_class Person
      resource_name  "restricted_people"
      expose_fields :id, :name
    end
  end
  
  it "should typecast values from strings for the parameters" do
    pending
  end
  
  it "should only allow fields that have been specified in the rest_resource" do
    pending
  end
  
  
end