require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "DataMapper::Adatapers::MerbRest" do
  
  before(:all) do
    DataMapper.setup(:merb_rest, "merb_rest://example.com")
    @repository = repository(:merb_rest)
    @adapter = @repository.adapter
  end
  
  it "should handle ssl"
  
  describe "create" do
    it{@adapter.should respond_to(:create)}
  end
  
  describe "read_many" do
    it{@adapter.should respond_to(:read_many)}
  end
  
  describe "read_one" do
    it{@adapter.should respond_to(:read_one)}
  end
  
  describe "update" do
    it{@adapter.should respond_to(:update)}
  end
  
  describe "delete" do
    it{@adapter.should respond_to(:delete)}
  end

end