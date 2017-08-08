require 'pp'
require 'pathname'
require 'yaml'
require 'test/unit'

require_relative 'conf'
require_relative '../src/lib/types'

include Blog::Index::Item

class INDEX_ITEM_TEST < Test::Unit::TestCase
  self.test_order = :defined

  class << self
    def startup 
      puts "\033[33mTEST #{File.basename __FILE__}\033[0m"
      @@repo = Github.new(YAML.load_file("#{File.dirname(__FILE__)}/test_data/github_repo")) 
    end

    def shutdown
    end
  end

  test "github repo name" do
    assert_equal("2link",  @@repo.name)
  end

  test "github repo url" do
    assert_equal("https://github.com/Mizuho32/2link",  @@repo.url)
  end

  test "github repo fork" do
    assert_equal(false,  @@repo.fork)
  end

  test "github repo description" do
    assert_equal("つらい",  @@repo.description)
  end

  test "github repo created_at" do
    assert_true(Time === @@repo.created_at)
  end

  test "github repo updated_at" do
    assert_true(Time === @@repo.updated_at)
  end

  test "github repo clone_url" do
    assert_equal("https://github.com/Mizuho32/2link.git", @@repo.clone_url)
  end

  test "to yaml test" do
    puts([ @@repo.to_h, 0 ].to_yaml)
  end
end
