require "dm-core"
DataMapper.setup(:default, "sqlite3::memory:")

class Foo
  include DataMapper::Resource
  
  property :id, Integer, :serial => true, :key => true
  property :name, String
end

Foo.auto_migrate!

Foo.create(:name => "Hello")