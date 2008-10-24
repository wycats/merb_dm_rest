##### Some classes to help with testing

class Person 
  include DataMapper::Resource
  property :id, Serial
  property :name, String, :nullable => false
  property :age, Integer
  property :dob, DateTime   
  
  repository(:tester) do
    property :nick, String
  end
  
  def self.my_custom_collection_finder(query = {})
    all(query)
  end
  
  def self.my_custom_member_finder(query = {})
    first(query)
  end
  
  def self.my_custom_instance_finder(id)
    get(id)
  end
  
end

class Cat
  include DataMapper::Resource
  
  property :id,                 Serial
  property :breed,              String
  property :dob,                Date
  property :number_of_kittens,  Integer
  property :mass,               Float
  property :alive,              Boolean
  
end

class Zoo
  include DataMapper::Resource
  property :id,       Serial
  property :name,     String
  property :city,     String
  property :lat,      String
  property :long,     String
end

class Merb::Authentication
  def fetch_user(session_data)
    Marshal.load(session_data)
  end
  
  def store_user(user)
    Marshal.dump(user)
  end
end


Person.fixture {{
  :name => /\w+/.gen,
  :age  => /\d{1,5}/.gen.to_i,
  :dob  => (DateTime.now + [1,-1][rand(2)] * rand(365))
}}

Cat.fixture{{
  :breed => /\w+/.gen,
  :dob   => (DateTime.now + [1,-1][rand(2)] * rand(3600)),
  :number_of_kittens => /\d{1,2}/.gen,
  :mass  => /\w{4,8}/.gen.to_f/1000.00,
  :alive => [true,false][rand(2)]
}}