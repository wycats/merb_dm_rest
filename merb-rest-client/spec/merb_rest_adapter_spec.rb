require File.join(File.dirname(__FILE__),  "spec_helper")

describe "DataMapper::Adatapers::MerbRest" do
  
  class Post 
    include DataMapper::Resource
    property :id, Serial
    property :title, String
    property :body, Text
    
    has n, :comments
  end
  
  class Comment
    include DataMapper::Resource

    property :id, Serial
    property :title, String
    property :body, Text
    
    belongs_to :post
  end
    
  
  before(:all) do
    DataMapper.setup(:default, "merb_rest://example.com")
    @repository = repository(:default)
    @adapter = @repository.adapter
  end
  
  it "should handle ssl"
  it "should setup an connection"
  it "should setup a connection with basic auth"
  
  describe "create" do
    it{@adapter.should respond_to(:create)}
    it "should send a post to the Post resource with parameters"    
    it "should return the number of created items"   
    it "should return 0 if a post does not save" 
  end
  
  describe "read_many" do
    it{@adapter.should respond_to(:read_many)}
    it "should send a get request to the Post resource"
    it "should send a get request to the Post resource with the requried parameters"
    it "should get all the objects"
  end
  
  describe "read_one" do
    it{@adapter.should respond_to(:read_one)}
    it "should send a get request to a specific Post Resource"
    it "should get the post"
  end
  
  describe "update" do
    it{@adapter.should respond_to(:update)}
    it "should send a put requrest to a specific Post resource"
    it "should send the dirty fields to update"
    it "should not send non-dirty fields"
    it "should return the number of updated items"
    it "should return 0 if an post does not update"
  end
  
  describe "delete" do
    it{@adapter.should respond_to(:delete)}
    it "should send a delete request to a specific resource"
    it "should send a delete request to the general resource with parameters"
    it "should delete all records"
  end
  
  describe "matchers" do
    it "should get all records with an eql matcher"
    it "should get all records with a like matcher"
    it "shoudl get all records with a not matcher"
    it "should get all records with a gt matcher"
    it "should get all records with a gte matcher"
    it "should get all records with a lt matcher"
    it "shoudl get all records with a lte matcher"
    it "should get records with multiple matchers"    
  end

  it "should order records"
  it "should handle date/time"
  it "should handle date"
  
end
