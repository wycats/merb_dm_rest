require File.dirname(__FILE__) + '/spec_helper'

describe "MerbRestServer (module)" do
  
  it "should have proper specs"
  
  # Feel free to remove the specs below
  
  before :all do
    Merb::Router.prepare { |r| r.add_slice(:MerbRestServer) } if standalone?
  end
  
  after :all do
    Merb::Router.reset! if standalone?
  end
  
  it "should be registered in Merb::Slices.slices" do
    Merb::Slices.slices.should include(MerbRestServer)
  end
  
  it "should be registered in Merb::Slices.paths" do
    Merb::Slices.paths[MerbRestServer.name].should == current_slice_root
  end
  
  it "should have an :identifier property" do
    MerbRestServer.identifier.should == "merb_rest_server"
  end
  
  it "should have an :identifier_sym property" do
    MerbRestServer.identifier_sym.should == :merb_rest_server
  end
  
  it "should have a :root property" do
    MerbRestServer.root.should == Merb::Slices.paths[MerbRestServer.name]
    MerbRestServer.root_path('app').should == current_slice_root / 'app'
  end
  
  it "should have a :file property" do
    MerbRestServer.file.should == current_slice_root / 'lib' / 'merb_rest_server.rb'
  end
  
  it "should have metadata properties" do
    MerbRestServer.description.should == "MerbRestServer is a chunky Merb slice!"
    MerbRestServer.version.should == "0.5.0"
    MerbRestServer.author.should == "Yehuda Katz"
  end
  
  it "should have :routes and :named_routes properties" do
    MerbRestServer.routes.should_not be_empty
  end

  it "should have an url helper method for slice-specific routes" do
    MerbRestServer.url(:controller => 'main', :action => 'show', :format => 'html').should == "/rest/main/show.html"
  end
  
  it "should have a config property (Hash)" do
    MerbRestServer.config.should be_kind_of(Hash)
  end
  
  it "should have bracket accessors as shortcuts to the config" do
    MerbRestServer[:foo] = 'bar'
    MerbRestServer[:foo].should == 'bar'
    MerbRestServer[:foo].should == MerbRestServer.config[:foo]
  end
  
  it "should have a :layout config option set" do
    MerbRestServer.config[:layout].should == :merb_rest_server
  end
  
  it "should have a dir_for method" do
    app_path = MerbRestServer.dir_for(:application)
    app_path.should == current_slice_root / 'app'
    [:view, :model, :controller, :helper, :mailer, :part].each do |type|
      MerbRestServer.dir_for(type).should == app_path / "#{type}s"
    end
    public_path = MerbRestServer.dir_for(:public)
    public_path.should == current_slice_root / 'public'
    [:stylesheet, :javascript, :image].each do |type|
      MerbRestServer.dir_for(type).should == public_path / "#{type}s"
    end
  end
  
  it "should have a app_dir_for method" do
    root_path = MerbRestServer.app_dir_for(:root)
    root_path.should == Merb.root / 'slices' / 'merb_rest_server'
    app_path = MerbRestServer.app_dir_for(:application)
    app_path.should == root_path / 'app'
    [:view, :model, :controller, :helper, :mailer, :part].each do |type|
      MerbRestServer.app_dir_for(type).should == app_path / "#{type}s"
    end
    public_path = MerbRestServer.app_dir_for(:public)
    public_path.should == Merb.dir_for(:public) / 'slices' / 'merb_rest_server'
    [:stylesheet, :javascript, :image].each do |type|
      MerbRestServer.app_dir_for(type).should == public_path / "#{type}s"
    end
  end
  
  it "should have a public_dir_for method" do
    public_path = MerbRestServer.public_dir_for(:public)
    public_path.should == '/slices' / 'merb_rest_server'
    [:stylesheet, :javascript, :image].each do |type|
      MerbRestServer.public_dir_for(type).should == public_path / "#{type}s"
    end
  end
  
  it "should have a public_path_for method" do
    public_path = MerbRestServer.public_dir_for(:public)
    MerbRestServer.public_path_for("path", "to", "file").should == public_path / "path" / "to" / "file"
    [:stylesheet, :javascript, :image].each do |type|
      MerbRestServer.public_path_for(type, "path", "to", "file").should == public_path / "#{type}s" / "path" / "to" / "file"
    end
  end
  
  it "should have a app_path_for method" do
    MerbRestServer.app_path_for("path", "to", "file").should == MerbRestServer.app_dir_for(:root) / "path" / "to" / "file"
    MerbRestServer.app_path_for(:controller, "path", "to", "file").should == MerbRestServer.app_dir_for(:controller) / "path" / "to" / "file"
  end
  
  it "should have a slice_path_for method" do
    MerbRestServer.slice_path_for("path", "to", "file").should == MerbRestServer.dir_for(:root) / "path" / "to" / "file"
    MerbRestServer.slice_path_for(:controller, "path", "to", "file").should == MerbRestServer.dir_for(:controller) / "path" / "to" / "file"
  end
  
  it "should keep a list of path component types to use when copying files" do
    (MerbRestServer.mirrored_components & MerbRestServer.slice_paths.keys).length.should == MerbRestServer.mirrored_components.length
  end
  
end