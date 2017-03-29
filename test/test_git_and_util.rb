require 'test/unit'
require 'pp'
require 'pathname'

require_relative 'conf'
require_relative '../src/lib/utils/git'
require_relative '../src/lib/utils/path_and_file'

REPOS = PROJ_ROOT + "/test_repos"

class Gen_Page_Test < Test::Unit::TestCase
  self.test_order = :defined
  include Blog::Util
  include Blog::Git

  class << self
    def startup 
    end
    
    def shutdown
    end
  end
  
  test "repo_name_and_relative_path test" do

    Dir.chdir PROJ_ROOT

    # Success
    path = "test_repos/test"
    repo_name, rel_path = repo_name_and_relative_path(path, REPOS)
    assert_equal("test", repo_name)
    assert_equal("./"  , rel_path)

    path = "test_repos/test"
    repo_name, rel_path = repo_name_and_relative_path(path, REPOS)
    assert_equal("test", repo_name)
    assert_equal("./"  , rel_path)

    path = "test_repos/test/dir/README.md"
    repo_name, rel_path = repo_name_and_relative_path(path, REPOS)
    assert_equal("test", repo_name)
    assert_equal("dir/README.md"  , rel_path)

    path = "test"
    repo_name, rel_path = repo_name_and_relative_path(path, REPOS)
    assert_equal("test", repo_name)
    assert_equal("./"  , rel_path)

    path = "test/./"
    repo_name, rel_path = repo_name_and_relative_path(path, REPOS)
    assert_equal("test", repo_name)
    assert_equal("./"  , rel_path)

    path = "test/dir/"
    repo_name, rel_path = repo_name_and_relative_path(path, REPOS)
    assert_equal("test", repo_name)
    assert_equal("dir/"  , rel_path)

    path = "test/dir/README.md"
    repo_name, rel_path = repo_name_and_relative_path(path, REPOS)
    assert_equal("test", repo_name)
    assert_equal("dir/README.md"  , rel_path)

  end

  test "remote_branch test" do
    Dir.chdir PROJ_ROOT + "/test_repos/test"

    assert_true( remote_branch.include?("master") )
  end

  test "remote_branch? test" do
    assert_equal("master", remote_branch?("master") )
  end

  test "local_branch test" do
    assert_true( local_branch.include?("master") )
  end

  test "local_branch? test" do
    assert_equal("master", local_branch?("master") )
  end

  test "commit_hash ? test" do
    hash = `git log --oneline`.split("\n").first[/(\w+)\s/, 1]
    assert_equal(hash, commit_hash?(hash, false))
  end

  test "commit_hash? test" do
    hash = `git log --oneline`.split("\n").first[/(\w+)\s/, 1]
    assert_equal(hash, commit_hash?(hash, false))
  end

  test "current_branch? test" do
    assert_equal("master", current_branch?)
    assert_true( current_branch?("master") )
    assert_false( current_branch?("develop") )
  end

  test "exist? test" do
    assert_true( exist?("dir", "master") )
    assert_true( exist?("dir/", "master") )
    assert_true( exist?("README.md", "master") )
    assert_true( exist?("dir/README.md", "master") )
    assert_false( exist?("empty/README.md", "master") )
    assert_false( exist?("README.md/", "master") )
  end

  test "ls test" do
    l = %w[README.md
    dir/
    screenshot.png]
    assert_equal(l.sort, ls("./"))
  end

  test "directory? test" do
    assert_false(directory?("README.md"))
    assert_false(directory?("./screenshot.png"))
    assert_false(directory?("emptydir"))
    assert_false(directory?("emptydir/"))
    assert_false(directory?("dir/README.md"))
    assert_false(directory?("dir/README.md/"))

    assert_true(directory?("dir/"))
    assert_true(directory?("dir"))
  end
    

end
