require File.dirname(__FILE__) + '/../spec_helper'

describe "MerbRestServer::Rest (controller)" do
  
  # Feel free to remove the specs below
  
  before :all do
    Merb::Router.prepare { |r| r.add_slice(:MerbRestServer, :path => "rest", :default_routes => false) } if standalone?
  end
  
  after :all do
    Merb::Router.reset! if standalone?
  end

  require File.dirname(__FILE__) + '/../spec_helper'

  describe "GET index" do
    it "routes GET /rest/foo to Rest#index" do
      controller = get("/rest/foo")
      controller.action_name.should == "index"
    end
  end

  describe "GET" do
    it "routes GET /rest/foo/1 to Rest#show :id => 1" do
      controller = get("/rest/foo/1")
      controller.action_name.should == "get"
      controller.params[:id].should == "1"
    end    
  end
  
  describe "POST" do
    it "routes POST /rest/foo/1 to Rest#update :id => 1" do
      controller = post("/rest/foo/1")
      controller.action_name.should == "post"
      controller.params[:id].should == "1"
    end    
  end
  
  describe "PUT" do
    it "routes PUT /rest/foo/1 to Rest#update :id => 1" do
      controller = put("/rest/foo/1")
      controller.action_name.should == "put"
      controller.params[:id].should == "1"
    end    
  end

  describe "DELETE" do
    it "routes DELETE /rest/foo/1 to Rest#update :id => 1" do
      controller = delete("/rest/foo/1")
      controller.action_name.should == "delete"
      controller.params[:id].should == "1"
    end
  end
  
  # it "should have access to the slice module" do
  #   controller = dispatch_to(MerbRestServer::Rest, :index)
  #   controller.slice.should == MerbRestServer
  #   controller.slice.should == MerbRestServer::Rest.slice
  # end
  # 
  # it "should have an index action" do
  #   controller = dispatch_to(MerbRestServer::Rest, :index)
  #   controller.status.should == 200
  #   controller.body.should contain('MerbRestServer')
  # end
  # 
  # it "should work with the default route" do
  #   controller = get("/merb_rest_server/main/index")
  #   controller.should be_kind_of(MerbRestServer::Rest)
  #   controller.action_name.should == 'index'
  # end
  # 
  # it "should work with the example named route" do
  #   controller = get("/merb_rest_server/index.html")
  #   controller.should be_kind_of(MerbRestServer::Main)
  #   controller.action_name.should == 'index'
  # end
  # 
  # it "should have routes in MerbRestServer.routes" do
  #   MerbRestServer.routes.should_not be_empty
  # end
  # 
  # it "should have a slice_url helper method for slice-specific routes" do
  #   controller = dispatch_to(MerbRestServer::Main, 'index')
  #   controller.slice_url(:action => 'show', :format => 'html').should == "/merb_rest_server/main/show.html"
  #   controller.slice_url(:merb_rest_server_index, :format => 'html').should == "/merb_rest_server/index.html"
  # end
  # 
  # it "should have helper methods for dealing with public paths" do
  #   controller = dispatch_to(MerbRestServer::Main, :index)
  #   controller.public_path_for(:image).should == "/slices/merb_rest_server/images"
  #   controller.public_path_for(:javascript).should == "/slices/merb_rest_server/javascripts"
  #   controller.public_path_for(:stylesheet).should == "/slices/merb_rest_server/stylesheets"
  # end
  # 
  # it "should have a slice-specific _template_root" do
  #   MerbRestServer::Main._template_root.should == MerbRestServer.dir_for(:view)
  #   MerbRestServer::Main._template_root.should == MerbRestServer::Application._template_root
  # end

end