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
      puts "\033[33mTEST #{File.basename __FILE__}\033[0m"
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

  test "exist_remote? test" do
    assert_true(  exist?("dir",              GitRevision::MASTER) )
    assert_true(  exist?("dir/",             GitRevision::MASTER) )
    assert_true(  exist?("README.md",        GitRevision::MASTER) )
    assert_true(  exist?("dir/README.md",    GitRevision::MASTER) )
    assert_false( exist?("empty/README.md",  GitRevision::MASTER) )
    assert_false( exist?("README.md/",       GitRevision::MASTER) )
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
  
  test "grep test" do
    grep = grep("hel", GitRevision.new("develop"), regexopt:"i")
    expected = <<-'EX'
1-/******************************************************************************
2:* FILE: hello.c
3-* DESCRIPTION:
4:*   A "hello world" Pthreads program.  Demonstrates thread creation and
5-*   termination.
6-* AUTHOR: Blaise Barney
--
12-#define NUM_THREADS  5
13-
14:void *PrintHello(void *threadid)
15-{
16-   long tid;
17-   tid = (long)threadid;
18:   printf("Hello World! It's me, thread #%ld!\n", tid);
19-   pthread_exit(NULL);
20-}
--
27-   for(t=0;t<NUM_THREADS;t++){
28-     printf("In main: creating thread %ld\n", t);
29:     rc = pthread_create(&threads[t], NULL, PrintHello, (void *)t);
30-     if (rc){
31-       printf("ERROR; return code from pthread_create() is %d\n", rc);
EX
    
    assert_true(grep.keys.include? "hello.c")
    assert_equal(
      expected.gsub(/\s+/,""),
      grep["hello.c"].gsub(/\s+/,""))
  end

  test "shebang test" do
    assert_equal("/******************************************************************************\r\n", shebang("hello.c", "test", GitRevision.new("develop")))
  end

  test "GitRevision local branch ok" do
    # fixme テスト用のリポジトリはローカルリポジトリとリモートリポジトリ混合か?

    rev = GitRevision.new("master")

    assert_equal("#{GIT_REMOTE}/master", rev.revision)
    assert_equal("master",               rev.to_s)
  end

  test "GitRevision remote branch ok" do

    rev = GitRevision.new("develop")

    assert_equal("#{GIT_REMOTE}/develop", rev.revision)
    assert_equal("develop",               rev.to_s)
  end

  test "GitRevision hash ok" do

    rev = GitRevision.new("06d24014f2f003b623c252d99eb99c88653e5183")

    assert_equal("06d24014f2f003b623c252d99eb99c88653e5183", rev.revision)
    assert_equal("06d24014f2f003b623c252d99eb99c88653e5183", rev.to_s)
  end

  test "GitRevision branch bad" do

    assert_raise(ArgumentError) {
      GitRevision.new("poi")
    }

  end

  test "GitRevision hash bad" do

    assert_raise(ArgumentError) {
      GitRevision.new("06d24014f2f003b623c252d99eb99c88653e5184")
    }

  end

end
