require File.dirname(__FILE__) + '/../spec_helper'

describe "Merb::DmRest::Fomats::Xml format marshalling" do
  
  before(:all) do
    Formats = Merb::Rest::Formats unless defined?(Formats)
  end
  
  describe "encoding" do

    it{Formats::Xml.should respond_to(:encode)}
    
    it "should not raise an error if it does receive a hash" do
      lambda do
        Formats::Xml.encode(:name => "String")
      end.should_not raise_error(ArgumentError)
    end
    
    it "should encode a number" do 
      result = Formats::Xml.encode(:age => 23)
      result.should have_tag(:i4, :name => 'age')
      result.should contain("23")
    end
    
    it "should encode an Array of strings" do
      result = Formats::Xml.encode(:my_array => ["A", "B", "C"])
      result.should have_tag(:list, :name => "my_array") do |list|
        list.to_s.should have_tag(:string)
      end
    end
    
    it "should encode a string value" do
      result = Formats::Xml.encode(:name => "String")
      result.should have_tag(:string, :name => "name")
      result.should contain("String")
    end
    
    it "should encode a symbol with a name" do
      result = Formats::Xml.encode(:name => :symbol)
      result.should have_tag(:string, :name => "name")
      result.should contain("symbol")
    end
    
    it "should encode a symbol with a name" do
      result = Formats::Xml.encode(:list => [:symbol])
      result.should have_tag(:string)
      result.should contain("symbol")
    end
    
    it "should encode a boolean true without a name" do
      result = Formats::Xml.encode(:list => [true])
      result.should have_tag(:boolean)
      result.should contain("1")
    end
    
    it "shoudl encode a blooean true with a name" do
      result = Formats::Xml.encode(:true => true)
      result.should have_tag(:boolean, :name => "true")
      result.should contain("1")
    end
    
    it "should encode a boolean false without a name" do
      result = Formats::Xml.encode(:list => [false])
      result.should have_tag(:boolean)
      result.should contain("0")
    end
    
    it "should encode a boolean false with a name" do
      result = Formats::Xml.encode(:false => false)
      result.should have_tag(:boolean)
      result.should contain("0")
    end
    
    it "should encode a float with a name" do
      result = Formats::Xml.encode(:a_double => 2.3)
      result.should have_tag(:double, :name => "a_double")
      result.should contain("2.3")
    end
    
    it "should encode a float without a name" do
      result = Formats::Xml.encode(:list => [2.3])
      result.should have_tag(:double)
      result.should contain("2.3")
    end
    
    it "should encode a struct with a name" do
      struct = Struct.new(:name, :age)
      result = Formats::Xml.encode(:a_struct => struct.new("phil", 24))
      result.should have_tag(:struct, :name => "a_struct") do |the_struct|
        the_struct = the_struct.to_s
        the_struct.should have_tag(:string, :name => "name")
        the_struct.should have_tag(:i4, :name => "age")
      end
    end
    
    it "should encode a struct without a name" do
      struct = Struct.new(:name, :age)
      result = Formats::Xml.encode(:list => [struct.new("fred", 21)])
      result.should have_tag(:struct) do |the_struct|
        the_struct = the_struct.to_s
        the_struct.should have_tag(:string, :name => "name")
        the_struct.should have_tag(:i4, :name => "age")
      end
    end
    
    it "should encode a hash without a name" do
      result = Formats::Xml.encode(:list => [{:name => "fred", :age => 21}])
      result.should have_tag(:struct) do |the_struct|
        the_struct = the_struct.to_s
        the_struct.should have_tag(:string, :name => "name")
        the_struct.should have_tag(:i4, :name => "age")
      end
    end
    
    it "should encode a hash with a name" do
      result = Formats::Xml.encode(:hash => {:name => :value})
      result.should have_tag(:struct, :name => "hash") do |ts|
        ts = ts.to_s
        ts.should have_tag(:string, :name => "name") do |string|
          string.to_s.should contain("value")
        end
      end
    end
    
    it "should encode a Time without a name" do
      time = Time.now
      time_str = time.strftime("%Y%m%dT%H:%M:%S%Z")
      result = Formats::Xml.encode(:list => [time])
      result.should match(%r[<dateTime\.iso8601>#{time_str}</dateTime\.iso8601>])
    end
    
    it "should encode a Time with a name" do
      time = Time.now
      time_str = time.strftime("%Y%m%dT%H:%M:%S%Z")
      result = Formats::Xml.encode(:time => time)
      result.should include("<dateTime.iso8601 name='time'>#{time_str}</dateTime.iso8601>")
    end
    
    it "should encode a Date with a name" do
      date = Date.today
      date_str = date.strftime("%Y%m%dT%H:%M:%S%Z")
      result = Formats::Xml.encode(:date => date)
      result.should include("<dateTime.iso8601 name='date'>#{date_str}</dateTime.iso8601>")
    end
    
    it "should encode a Date witout a name" do
      date = Date.today
      date_str = date.strftime("%Y%m%dT%H:%M:%S%Z")
      result = Formats::Xml.encode(:list => [date])
      result.should include("<dateTime.iso8601>#{date_str}</dateTime.iso8601>")
    end
    
    it "should encode a DateTime without a name" do
      datetime = DateTime.now
      date_str = datetime.strftime("%Y%m%dT%H:%M:%S%Z")
      result = Formats::Xml.encode(:list => [datetime])
      result.should include("<dateTime.iso8601>#{date_str}</dateTime.iso8601>")
    end
    
    it "should encode a DateTime with a name" do
      datetime = DateTime.now
      date_str = datetime.strftime("%Y%m%dT%H:%M:%S%Z")
      result = Formats::Xml.encode(:datetime => datetime)
      result.should include("<dateTime.iso8601 name='datetime'>#{date_str}</dateTime.iso8601>")
    end
    
    it "should encode a nil with a name" do
      result = Formats::Xml.encode(:the_nil => nil)
      result.should include("<nil name='the_nil'/>")
    end
    
    it "should encode a nil without a name" do
      result = Formats::Xml.encode(:list => [nil])
      result.should include("<nil/>")
    end
  end
  
  describe "decoding" do
    it{Formats::Xml.should respond_to(:decode)}
  
    it "should decode a string" do
      string = "<string>Fred</string>"
      Formats::Xml.decode(string).should == "Fred"
    end
    
    it "should decode a string with a name" do
      string = "<struct><string name='name'>Fred</string></struct>"
      Formats::Xml.decode(string).should == {:name => "Fred"}
    end
    
    it "should decode an integer" do
      string = "<i4>42</i4>"
      Formats::Xml.decode(string).should == 42
    end
    
    it "should decode an integer with a name" do
      string = "<struct><i4 name='answer'>42</i4></struct>"
      Formats::Xml.decode(string).should == {:answer => 42}
    end
    
    it "should decode a float" do
      string = "<double>4.2</double>"
      Formats::Xml.decode(string).should == 4.2
    end
    
    it "should decode a float with a name" do
      string = "<struct><double name='wrong_answer'>4.2</double></struct>"
      Formats::Xml.decode(string).should == {:wrong_answer => 4.2}
    end
    
    it "should decode a DateTime" do
      date_time = DateTime.now
      ds = date_time.strftime("%Y%m%dT%H:%M:%S%Z")
      string = "<dateTime.iso8601>#{ds}</dateTime.iso8601>"
      result = Formats::Xml.decode(string)
      result.to_s.should == date_time.to_s
    end
    
    it "should decode a DateTime with a name" do
      date_time = DateTime.now
      ds = date_time.strftime("%Y%m%dT%H:%M:%S%Z")
      string = "<struct><dateTime.iso8601 name='dob'>#{ds}</dateTime.iso8601></struct>"
      result = Formats::Xml.decode(string)
      result[:dob].to_s.should == date_time.to_s
    end
    
    it "should decode an Array of Strings" do
      string = "<list><string>a</string><string>b</string><string>c</string></list>"
      result = Formats::Xml.decode(string)
      result.should == %w(a b c)
    end
    
    it "should decode an Array of integers" do
      string =<<-XML
        <list>
          <i4>1</i4>
          <i4>2</i4>
          <i4>3</i4>
        </list>
      XML
      result = Formats::Xml.decode(string)
      result.should == [1,2,3]
    end
    
    it "should decode a mixed array" do
      string =<<-XML
        <list>
          <i4>1</i4>
          <string>Fred</string>
          <boolean>1</boolean>
          <nil/>
        </list>
      XML
      result = Formats::Xml.decode(string)
      result.should == [1,"Fred",true,nil]
    end
    
    it "should decode a named list" do
      string =<<-XML
        <struct>
          <list name='my_list'>
            <i4>1</i4>
            <i4>2</i4>
          </list>
        </struct>
      XML
      result = Formats::Xml.decode(string)
      result[:my_list].should == [1,2]
    end
    
    it "should decode a nested array" do
      string =<<-XML
        <list>
          <i4>1</i4>
          <list>
            <string>nested</string>
          </list>
        </list>
      XML
      result = Formats::Xml.decode(string)
      result.should == [1,["nested"]]
    end
    
    it "should decode a struct to a hash" do
      string =<<-XML
        <struct>
          <string name='name'>Fred</string>
          <list name='my_list'>
            <i4>1</i4>
            <string>five</string>
          </list>
        </struct>
      XML
      result = Formats::Xml.decode(string)
      result.should == {:name => "Fred", :my_list => [1,"five"]}
    end   
    
    it "should raise an error for any children of a struct that do not have a name" do
      string =<<-XML
        <struct>
          <string name='name'>Fred</string>
          <list>
            <i4>1</i4>
            <string>five</string>
          </list>
        </struct>
      XML
      lambda do
        result = Formats::Xml.decode(string)
      end.should raise_error(Exception, "children of struct must have a name attribute")
    end
    
    it "should deal with a collection of structs" do
      string =<<-XML
        <list>
          <struct>
            <string name="name">Fred</string>
            <i4 name="age">23</i4>
          </struct>
          <struct>
            <string name="name">Graeme</string>
            <i4 name="age">45</i4>
          </struct>
          <struct>
            <string name="name">Wilma</string>
            <i4 name="age">21</i4>
          </struct>
        </list>
      XML
      result = Formats::Xml.decode(string)
      result.should == [
          {:name => "Fred",   :age => 23},
          {:name => "Graeme", :age => 45},
          {:name => "Wilma",  :age => 21}
        ]
    end
    
    it "should deal with a collection of structs in a named list" do
      string =<<-XML
        <struct>
          <list name="users">
            <struct>
              <string name="name">Fred</string>
              <i4 name="age">23</i4>
            </struct>
            <struct>
              <string name="name">Graeme</string>
              <i4 name="age">45</i4>
            </struct>
            <struct>
              <string name="name">Wilma</string>
              <i4 name="age">21</i4>
            </struct>
          </list>
        </struct>      
      XML
      result = Formats::Xml.decode(string)
      result.should == {:users => [
          {:name => "Fred",   :age => 23},
          {:name => "Graeme", :age => 45},
          {:name => "Wilma",  :age => 21}
        ]}
    end
    
  end
  
  describe "integration" do
    
    def reversible?(params)
      Formats::Xml.decode(Formats::Xml.encode(params)).should == params
    end
    
    it "should be reversible " do
      reversible? :name => "fred"
    end
    
    it "shoudl go back and forth with a list" do
      reversible? :users => ["fred", "barney", "wilma", "betty"]
    end
    
    it "should go back and forth with a hash" do
      reversible? :a_hash => {:numbers => 1}
    end
    
    it "shodul go back and forth with a nested list" do
      reversible? :a_list => [1,2,3,"Fred", {:stuff => ["in", "a", "hash"]}]
    end
    
    it "should go back and forth with a nested hash" do
      reversible? :a_hash => {:stuff => [1,2,3,{:complex => "thing"}, 2.3]}
    end
    
  end

end