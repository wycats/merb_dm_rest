$TESTING=true

require 'rubygems'
require 'spec'
require 'hpricot'
require 'merb-core'

module Merb
  module Test
    module Rspec
    end
  end
end

require 'merb-core'
require 'merb-core/test/matchers/view_matchers'


require File.join(File.dirname(__FILE__), "..", "lib", "merb-rest-formats")

Spec::Runner.configure do |config|
  config.include(Merb::Test::Rspec::ViewMatchers)
end
