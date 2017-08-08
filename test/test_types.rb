require 'test/unit'
require 'pp'
require 'pathname'
require 'yaml'

require_relative 'conf'
require_relative '../src/lib/types'

include Blog::Index::Item

class Dummy < IndexItem
  type :dummy

  def self.name
    @@repo[:name]
  end
end

class TYPES_TEST < Test::Unit::TestCase
  self.test_order = :defined

  class << self
    def startup 
      puts "\033[33mTypes TEST\033[0m"
    end

    def shutdown
    end
  end

  test "Derived IndexItem class test" do

    repo = {name: "Test"}

    assert_equal(:dummy,  Dummy.type)
    assert_equal("Test",  Dummy.wrap(repo).name)
  end

end
