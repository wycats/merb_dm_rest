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
    property :body,  Text
    property :created_at, DateTime
    
    belongs_to :post
  end
    
  
  before(:all) do
    DataMapper.setup(:default, "sqlite3::memory:")
    repository(:default).auto_migrate!
    
    DataMapper.setup(:merb_rest, "merb_rest://example.com")
    @repository = repository(:merb_rest)
    @adapter = @repository.adapter
  end
  

    
  it "should handle ssl" do
    @response = mock("response")
    @request = Net::HTTP::Get.new("http://example.com")
    DataMapper.setup(:merb_rest_ssl,  :adapter  => "merb_rest",
                                      :host     => "example.com",
                                      :scheme   => "https",
                                      :port     => 443,
                                      :username => "hassox",
                                      :password => "password",
                                      :format   => :json)
    adapter = repository(:merb_rest_ssl).adapter
    Net::HTTP::Get.should_receive(:new).and_return(@request)
    @request.should_receive(:use_ssl=).with(true)
    Net::HTTP.should_receive(:new).and_return(@response)
    @response.should_receive(:start).and_return(@response)
    @response.stub!(:error!).and_return(@response)
    @response.stub!(:body).and_return(JSON.generate([{:id => 3, :title => "blah"}]))
    
    repository(:merb_rest_ssl){Comment.all.each{}}
  end
  
  
  it "should setup a connection with basic auth" do
    req = Net::HTTP::Get.new("http://example.com")
    req.should_receive(:basic_auth)
    Net::HTTP::Get.should_receive(:new).and_return(req)
    Net::HTTP.should_receive(:new).and_return(mock("response", :null_object => true, :body => JSON.generate([{:id => 3, :title => "blah"}])))
    Post.all.each{}
  end
  

  
  describe "create" do
    before(:each) do
      @response = mock("response")
      @adapter.stub!(:abstract_request).and_return(@response)
      @response.stub!(:body).and_return(@json)
      @response.stub!(:code).and_return("200")
    end
    
    it{@adapter.should respond_to(:create)}
    
    it "should create a post" do
      @adapter.should_receive(:api_post).with("posts", "post" => {"title" => "a title", "body" => "a body"}).and_return(@response)
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
    
    it "should handle date/time" do
      d = DateTime.now
      @adapter.should_receive(:api_get) do |location, params|
        location.should == "comments"
        params["created_at.eql"].should == d.to_s
        @response
      end
      Comment.all(:created_at => d).each{}
    end


    it "should handle date" do
      d = Date.today
      @adapter.should_receive(:api_get) do |location, params|
        location.should == "comments"
        params["created_at.eql"].should == d.to_s
        @response
      end
      Comment.all(:created_at => d).each{}
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
      @adapter.should_receive(:api_get).with("posts",   "id.eql"  => "3",
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
      @response.stub!(:code).and_return("200")
      @post = Post.new(:title => "my_title", :body => "my_body", :id => 16)
      @post.stub!(:new_record?).and_return(false)
      @adapter.stub!(:read_many).and_return([@post])
    end
    
    it{@adapter.should respond_to(:update)}
    
    it "should send a put request to a specific Post resource" do
      @adapter.should_receive(:api_put).and_return(@response)
      @post.update_attributes(:title => "another title")
    end
    
    it "should send the dirty fields to update" do
      @adapter.should_receive(:api_put) do |location, attributes|
        location.should == "posts"
        attributes["title"].should == "yet another"
        @response
      end
      @post.update_attributes(:title => "yet another")
    end
    
    it "should return false if the update didn't happen" do
      @response.should_receive(:code).and_return("500")
      @post.update_attributes(:title => "something").should be_false
    end
    
    it "should return true if the update did happen" do
      @response.should_receive(:code).and_return("200")
      @post.update_attributes(:body => "something different").should be_true
    end
  end
  
  describe "delete" do
    before(:each) do
      @response = mock("response")
      @adapter.stub!(:abstract_request).and_return(@response)
      @response.stub!(:body).and_return(@json)
      @response.stub!(:code).and_return("200")
      @post = Post.new(:title => "my_title", :body => "my_body", :id => 16)
      @post.stub!(:new_record?).and_return(false)
      @adapter.stub!(:read_many).and_return([@post])
    end
    
    it{@adapter.should respond_to(:delete)}
    
    it "should send a delete request to a specific resource" do
      @adapter.should_receive(:api_delete) do |location, attributes|
        location.should == "posts"
        attributes["id.eql"].should == "16"
        @response
      end
      @post.destroy
    end
    
    it "return false if the item is deleted" do
      @response.should_receive(:code).and_return("500")
      @post.destroy.should be_false
    end
    
    it "should return true if the item is deleted" do
      @response.should_receive(:code).and_return("200")
      @post.destroy.should be_true
    end
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
