require 'test/unit'
require 'pp'
require 'pathname'

require_relative 'conf'
require_relative '../src/lib/utils/util'

REPOS = PROJ_ROOT + "/test_repos"

class Gen_Page_Test < Test::Unit::TestCase
  self.test_order = :defined
  include Blog::Util

  class << self
    def startup 
    end

    def shutdown
    end
  end

  test "unused_num test" do
    assert_equal(0, unused_num([]))
    assert_equal(1, unused_num([0]))
    assert_equal(2, unused_num([0, 1]))
    assert_equal(3, unused_num([0, 1, 2]))
    assert_equal(4, unused_num([0, 1, 2, 3]))

    assert_equal(1, unused_num([0, 2, 3]))
    assert_equal(1, unused_num([0, 3]))
    assert_equal(2, unused_num([0, 1, 3]))
  end

end
