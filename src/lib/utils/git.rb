# encoding: utf-8
require 'open3'

module Blog
  module Git
    extend self

    public 

    def run_git_cmd(cmd, dir:"./")
      res = Open3.capture3(%Q{git -C "#{dir}" #{cmd}})
      unless res.last.exitstatus.zero? then
        raise RuntimeError.new(res[1]) if res[1] =~ /Not a git repository/
      end
      res
    end

    def remote_branch
      result = Open3.capture3("git branch -r --no-color")
      raise RuntimeError.new(result[1]) unless result.last.exitstatus.zero?
      result
        .first
        .split("\n")
        .select{|b| !b.include?("/HEAD")}
        .map{|b| b[/^[^\/]+\/([^\/]+)/, 1]}
    end

    def remote_branch?(name)
      return name if remote_branch().include?(name)
      false
    end

    def local_branch
      result = Open3.capture3("git branch --no-color")
      raise RuntimeError.new(result[1]) unless result.last.exitstatus.zero?
      result
        .first
        .split("\n")
        .map{|b| b[2..-1]}
    end

    def local_branch?(name)
      return name if local_branch().include?(name)
      false
    end 

    def commit_hash?(hash, is_branch)
      if (result = Open3.capture3("git cat-file -e #{hash}^{commit}")).last.exitstatus.zero? then
        return hash if !is_branch
      else
        raise RuntimeError.new(result[1]) if result[1] =~ /repository/
      end
      false
    end 

    def current_branch?(name=nil)
      res = Open3.capture3("git symbolic-ref --short HEAD")
      unless res.last.exitstatus.zero? then
        raise RuntimeError.new(res[1]) if res[1] =~ /repository/
        return false
      end

      if name.nil? then
        res.first.strip
      else
        res.first.strip == name
      end
    end

    def exist?(path, gitrev = "master")

      res = Open3.capture3("git show #{gitrev}:#{path} > /dev/null")
      unless res.last.exitstatus.zero? then
        raise RuntimeError.new(res[1]) if res[1] =~ /repository/
        return false
      end

      true
    end

    def ls(path, gitrev = "master")
      res,e,p = run_git_cmd("show #{gitrev}:#{path}")
      return [] unless p.exitstatus.zero?

      res
        .split("\n")[2..-1]
    end

    def directory?(path, gitrev = "master")
      return true if path == "./"

      dir = "./" + File.dirname(path)
      basename = File.basename(path) + "/"
      list = ls(dir, gitrev)

      list.include? basename  
    end

    def dirname(relative_path)
      ?. + File.expand_path(File.dirname(relative_path), ?/)
    end

    def grep(pat, rev, regexopt:"", opt:"-C 2 -n  -I")
      out, err, p = run_git_cmd("grep --break --heading #{opt} -E#{regexopt} '#{pat}' #{rev}")
      return {} unless p.exitstatus.zero?
      out
        .split(/^$/)
        .inject({}){|hash, code| 
          hash[code[/^[^:]+:(.+)$/,1]] = code[/\A.+?\n(.+)\z/m, 1]
          hash
        }
    end

    def shebang(rel_path, repo, gitrev="master")
      out, err, p = run_git_cmd("show #{gitrev}:#{rel_path} | head -n 1", dir:(REPOS_ROOT+"/#{repo}"))
      return "" unless p.exitstatus.zero?
      return out
    end

  end
end

module Blog
  module Git

    class GitRevision
      
      def check(rev_string)
        if b = Git.remote_branch?(rev_string)  then
          :branch
        elsif  Git.commit_hash?(rev_string, b) then
          :hash
        else
          raise ArgumentError.new("Invalied git revision '#{rev_string}'")
        end
      end

      def initialize(rev_string)
        @type     = check(rev_string)
        @revision = rev_string
      end
      
      def to_s
        @revision
      end

      def inspect
        to_s()
      end

      def revision
        if @type == :branch then
          "#{GIT_REMOTE}/#{@revision}"
        else
          @revision
        end
      end

    end

  end
end
