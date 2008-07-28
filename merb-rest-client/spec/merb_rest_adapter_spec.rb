require File.join(File.dirname(__FILE__),  "spec_helper")

require 'dm-serializer'

describe "DataMapper::Adatapers::MerbRest" do
  
  class Post 
    include DataMapper::Resource
    
    def self.default_repository_name
      :merb_rest
    end
    
    property :id, Serial
    property :title, String
    property :body, Text, :lazy => false
    
    has n, :comments
  end
  
  class Comment
    include DataMapper::Resource
    
    def self.default_repository_name
      :merb_rest
    end

    property :id, Serial
    property :title, String
    property :body, Text, :lazy => false
    
    belongs_to :post
  end
    
  
  before(:all) do
    DataMapper.setup(:default, "sqlite3::memory:")
    repository(:default).auto_migrate!
    
    DataMapper.setup(:merb_rest, "merb_rest://example.com")
    @repository = repository(:merb_rest)
    @adapter = @repository.adapter
  end
  

    
  it "should handle ssl"
  it "should setup an connection"
  it "should setup a connection with basic auth"
  
  describe "create" do
    before(:each) do
      @response = mock("response")
      @adapter.stub!(:abstract_request).and_return(@response)
      @response.stub!(:body).and_return(@json)
    end
    
    it{@adapter.should respond_to(:create)}
    
    it "should create a post" do
      @adapter.should_receive(:api_post).with("posts", "post" => {"title" => "a title", "body" => "a body"})
      Post.create(:title => "a title", :body => "a body")
    end
    
    it "should return the created item" do
      post = Post.create(:title => "a title", :body => "a body")
      post.should be_a_kind_of(Post)
      post.title.should == "a title"
    end
  end
  
  describe "read_many" do  
    before(:all) do
      @hash = [{"title" => "title", "body" => "body", "id" => 3},{"title" => "another title", "body" => "another body", "id" => 42}]
      @json = JSON.generate(@hash)
    end
      
    before(:each) do
      @response = mock("response")
      @adapter.stub!(:abstract_request).and_return(@response)
      @response.stub!(:body).and_return(@json)
    end
    
    it{@adapter.should respond_to(:read_many)}
    
    it "should send a get request to the Post resource" do
      @adapter.should_receive(:api_get).with("posts", {"order" => ["id.asc"], "fields" => ["id", "title", "body"]}).and_return(@response)
      Post.all.inspect
    end
    
    it "should return instantiated objects" do
      @adapter.should_receive(:api_get).with("posts", {"order" => ["id.asc"], "fields" => ["id", "title", "body"]}).and_return(@response)
      @adapter.should_receive(:parse_results).and_return(@hash)
      Post.all.inspect
    end
    
    it "should load all the objects" do
      Post.all.each{|p| p.should be_a_kind_of(Post)}
    end
    
    it "should load the objects correctly" do
      post = Post.all.map{|p| p}.first
      post.title.should == "title"
      post.body.should == "body"
      post.id.should == 3
    end
    
    it "Should load all the objects correctly" do
      posts = Post.all(:order => [:id.asc]).map{|p| p}
      posts.should have(2).items
      posts[0].id.should == 3
      posts[0].title.should == "title"
      posts[0].body.should == "body"
      posts[1].id.should == 42
      posts[1].title.should == "another title"
      posts[1].body.should == "another body"
    end
    
    describe "read many with conditions" do
      
      it "should use a get with conditional parameters" do
        @adapter.should_receive(:api_get).with("posts", { "title.like" => "tit%", 
                                                          "body.eql" => "body",
                                                          "order" => ["id.asc"], 
                                                          "fields" => ["id", "title", "body"]
                                                          }).and_return(@response)
        Post.all(:title.like => "tit%", :body.eql => "body").each{}
      end
      
      it "should add a fields option for fields" do
        @adapter.should_receive(:api_get).with("posts", "title.like"  => "tit%", 
                                                        "order"       => ["id.asc"], 
                                                        "fields"      => ["id", "body"]).and_return(@response)
        Post.all(:title.like => "tit%", :fields => [:id, :body]).each{}
      end
      
      it "should add the options for limit" do
        @adapter.should_receive(:api_get).with("posts",   "title.like"  => "tit%",
                                                          "order"       => ["id.asc"],
                                                          "fields"      => ["id", "title", "body"],
                                                          "limit"       => 5).and_return(@response)
        Post.all(:title.like => "tit%", :limit => 5).each{}
      end
      
      it "should allow for options with offset" do
        @adapter.should_receive(:api_get).with("posts",  "order"   => ["id.asc"],
                                                          "fields"  => ["id", "title", "body"],
                                                          "offset"  => 23).and_return(@response)
        Post.all(:offset => 23).each{}
      end
      
      it "should allow for unique flag" do
        @adapter.should_receive(:api_get).with("posts",  "order"   => ["id.asc"],
                                                          "fields"  => ["id", "title", "body"],
                                                          "unique"  => true).and_return(@response)
        Post.all(:unique => true).each{}
      end
    end
    
  end
  
  describe "read_one" do
    
    before(:all) do
      @hash = [{"title" => "title", "body" => "body", "id" => 3},{"title" => "another title", "body" => "another body", "id" => 42}]
      @json = JSON.generate(@hash)
    end
    
    before(:each) do
      @response = mock("response")
      @adapter.stub!(:abstract_request).and_return(@response)
      @response.stub!(:body).and_return(@json)
    end
    
    it{@adapter.should respond_to(:read_one)}
    
    it "should send a get request to a specific Post Resource" do
      @adapter.should_receive(:api_get).with("posts",   "id.eql"  => 3,
                                                        "fields"  => ["id", "title", "body"],
                                                        "order"   => ["id.asc"],
                                                        "limit"   => 1
                                                        ).and_return(@response)
      
      Post.get(3).should_not be_nil
    end
    
    it "should send a get the first post" do
      post = Post.first
      post.should_not be_nil
      post.id.should == 3
      post.title.should == "title"
      post.body.should == "body"
    end
    
    it "should get the provided post" do
      @response.stub!(:body).and_return(JSON.generate([{"title" => "another title", "body" => "another body", "id" => 42}]))
      post = Post.get(42)
      post.should_not be_nil
      post.id.should == 42
      post.title.should == "another title"
      post.body.should == "another body"
    end
  end
  
  describe "update" do
    before(:each) do
      @response = mock("response")
      @adapter.stub!(:abstract_request).and_return(@response)
      @response.stub!(:body).and_return(@json)
      @post = Post.new(:title => "my_title", :body => "my_body", :id => 16)
      @post.stub!(:new_record?).and_return(false)
    end
    
    it{@adapter.should respond_to(:update)}
    
    it "should send a put requrest to a specific Post resource" do
      @adapter.should_receive(:api_put).and_return(@response)
      @post.update_attributes(:title => "another title")      
    end
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

  describe "formats" do
    describe "json" do
      before do
        @post = Post.new(:title => "title", :body => "body", :id => 3)
        @post_json = @post.to_json
      end
      
      it "should parse the json of an object" do
        result = @adapter.send(:parse_results, @post_json)
        result.should == {"title" => "title", "body" => "body", "id" => 3}
      end
    end
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
