require "dm-core"
require "dm-serializer"

DataMapper.setup(:default, "sqlite3::memory:")
DataMapper.setup(:tester, "sqlite3::memory:")

module DataMapper::Resource
  include DataMapper::Serialize
end

class Foo
  include DataMapper::Resource
  
  property :id, Integer, :serial => true, :key => true
  property :name, String
end

Foo.auto_migrate!

Foo.create(:name => "Mock1")
Foo.create(:name => "Mock2")
Foo.create(:name => "Mock3")
