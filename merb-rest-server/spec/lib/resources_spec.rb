require File.dirname(__FILE__) + '/../spec_helper'

describe MerbRestServer do
  
  before(:all) do
    MerbRestServer.resources.clear
    module MerbRestServer
      class Staff < RestResource
        resource_class Person
        resource_name  "staff"
      end
      
      class Student < RestResource
        resource_class Person
        resource_name  "students"
      end
    end
  end
  
  after(:all) do
    MerbRestServer.resources.clear
  end
  
  it "should get a list of all resources" do
    MerbRestServer.resources.should include(MerbRestServer::Staff)
    MerbRestServer.resources.should include(MerbRestServer::Student)
  end 
  
  it "should provide a list of options for all resources" do
    expected = {
      "staff"     => {:methods=>["DELETE", "GET", "OPTIONS", "POST", "PUT"], :resource_name=>"staff", :path=>"/staff", :fields=>[{:id=>Integer}, {:name=>String}, {:age=>Integer}, {:dob=>DateTime}]},
      "students"  => {:methods=>["DELETE", "GET", "OPTIONS", "POST", "PUT"], :resource_name=>"students", :path=>"/students", :fields=>[{:id=>Integer}, {:name=>String}, {:age=>Integer}, {:dob=>DateTime}]}
    }
    MerbRestServer.resource_options.should == expected    
  end
  
  it "should provide access to a resource based on resource name as string" do
    MerbRestServer["staff"].should == MerbRestServer::Staff
    MerbRestServer["students"].should == MerbRestServer::Student
  end
  
  it "shoudl provide access to a resource based on resource name as symbol" do
    MerbRestServer[:staff].should == MerbRestServer::Staff
    MerbRestServer[:students].should == MerbRestServer::Student
  end

end