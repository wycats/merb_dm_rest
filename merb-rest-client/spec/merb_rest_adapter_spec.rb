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
    DataMapper.setup(:default, "sqlite3::memory:")
    repository(:default).auto_migrate!
    
    DataMapper.setup(:merb_rest, "merb_rest://example.com")
    @repository = repository(:merb_rest)
    @adapter = @repository.adapter
    
    1.upto(10) do |n|
      Post.create(:title => "title #{n}", :body => "body #{n}")
    end
  end
    
  it "should handle ssl"
  it "should setup an connection"
  it "should setup a connection with basic auth"
  
  describe "create" do
    it{@adapter.should respond_to(:create)}
    it "should send a post to the Post resource with parameters" do
      pending
      params = {:post => {:title => "created post", :body => "created_body"}}
      RestClient.should_receive(:post).with("http://example.com/posts", params.to_params)
      Post.create(params[:post])
    end
    
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
    # it{@adapter.should respond_to(:delete)}
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
  
  describe "api methods" do
    before do
      @response = mock("response",    :null_object => true)
      @request  = mock("request",     :null_object => true)
      @http     = mock("http",        :null_object => true)
      @conn     = mock("connecction", :null_object => true)
      Net::HTTP.stub!(:new).and_return(@response)
      DataMapper.setup(:mr_api, "merb_rest://hassox:password@example.com/rest")
      @mra = repository(:mr_api).adapter
    end
    
    describe "all_methods", :shared => true do
      
      before do
        @class.stub!(:new).and_return(@request)
        @request.should_receive(:basic_auth).with("hassox", "password")
      end
      
      it "should recieve a path and a hash" do
        @class.should_receive(:new).with("/rest/path").and_return(@request)
        @mra.send(@method, "path", :one => "two")
      end
      
      it "should set the form data as part of the request" do
        @mra.send(@method, "path", :one => "two")
      end
      
      it "should use a NetHTTP::Post connection" do
        Net::HTTP.should_receive(:new).and_return(@conn)
        @conn.should_receive(:start).and_yield(@conn)
        @conn.should_receive(:request).with(@request).and_return(@response)
        @mra.send(@method, "path", :one => "two")
      end
      
    end
    
    describe "api_post" do
      before do
        @method = :api_post
        @class = Net::HTTP::Post
      end
      
      it_should_behave_like "all_methods"
    end
    
    describe "api_get" do
      before do
        @method = :api_get
        @class = Net::HTTP::Get
      end
      
      it_should_behave_like "all_methods"
    end
    
    describe "api_put" do
      before do
        @method = :api_put
        @class = Net::HTTP::Put
      end
      
      it_should_behave_like "all_methods"
    end
    
    describe "api_delete" do
      before do
        @method = :api_delete
        @class = Net::HTTP::Delete
      end
      
      it_should_behave_like "all_methods"
    end
    
    describe "api_options" do
      before do
        @method = :api_options
        @class = Net::HTTP::Options
      end
      
      it_should_behave_like "all_methods"
    end
  end
  
end
