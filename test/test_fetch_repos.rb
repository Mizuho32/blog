require 'test/unit'
require 'pp'
require 'pathname'
require 'yaml'

require_relative 'conf'
require_relative '../src/lib/fetch_repos'

class FETCH_REPOS_TEST < Test::Unit::TestCase
  self.test_order = :defined
  include Blog::Fetch

  class << self
    def startup 
      puts "\033[33mFetch repos TEST\033[0m"
    end

    def shutdown
    end
  end

  test "validate_fetch_conf ok test" do
    conf = <<-"YAML"
:github:
  - :poi
  - :pai
YAML
    assert_equal({github:[:poi,:pai]}, validate_fetch_conf(YAML.load(conf)) )
  end

  test "validate_fetch_conf false test" do
    conf = <<-"YAML"
:bitbucket:
  - :poi
  - :pai
YAML
    assert_false( validate_fetch_conf(YAML.load(conf)) )
  end

  test "validate_fetch_conf warn test" do
    conf = <<-"YAML"
:github:
  - :poi
  - :pai
:bitbucket:
  - :poi
  - :pai
YAML
      assert_equal({github:[:poi,:pai]}, validate_fetch_conf(YAML.load(conf)) )
    end

end
