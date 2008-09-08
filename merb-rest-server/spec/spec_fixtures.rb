##### Some classes to help with testing

class Person 
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  property :age, Integer
  property :dob, DateTime   
  
  repository(:tester) do
    property :nick, String
  end
end

class Cat
  include DataMapper::Resource
  
  property :id,                 Serial
  property :breed,              String
  property :dob,                DateTime
  property :number_of_kittens,  Integer
  property :mass,               Float
  property :alive,              Boolean
  
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