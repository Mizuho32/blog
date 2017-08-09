require 'octokit'

require_relative 'types'

module Blog
  module Fetch
    extend self
    GITHUB_CACHE_NAME = :github

    public

    def fetch_from_github?
      unless File.exist?(FETCH_CACHE_ROOT + "/#{GITHUB_CACHE_NAME}") then
        true
      else
        print "overwrite fetched cache? [y/n] >>"
        STDIN.gets =~ /y(?:es)?/
      end
    end

    def github(names)
      return Blog::Util.restore(FETCH_CACHE_ROOT + "/#{GITHUB_CACHE_NAME}") unless fetch_from_github?

      client = Octokit::Client.new

      cache = names.inject({}){|result, name|
        puts "User #{name}\n"
        user  = Octokit.user(s = name.to_s)
        repos = client.repositories(s)
        result[user] = repos
        result
      }

      Blog::Util.save(FETCH_CACHE_ROOT + "/#{GITHUB_CACHE_NAME}", cache)
      cache
    end

    def validate_fetch_conf(conf)
      keys = conf.keys
      methods = Blog::Fetch.instance_methods
      ok      = keys & methods
      non     = keys - ok

      if ok.empty? then
        puts <<-"ERR"
\033[31mERROR!\033[0m
"#{non.join(", ")}", Not supported
No valid repos

ERR
        return false
      elsif !non.empty? then
        puts <<-"WARN"
\033[33mWARNING!\033[0m
"#{non.join(", ")}", Not supported

WARN
      end

      conf.select{|k,v| ok.include? k}
    end

    def fetch_repos(conf)
      return unless hosts = validate_fetch_conf(conf)

      hosts.inject({}){|o, (h, user_names)|
        o[h] = Blog::Fetch.send(h, *[user_names])
        o
      }
    end

    def index_model(caches, cond = ->(){ true } )

      order = {}

      order[:repos] = tmp = caches.map{|hosting, owner_repos|
        owner_repos.values.map{|repos| repos.map{|repo| Blog::Index::Item::Generic[hosting].new(repo.to_h) }}
      }.flatten.sort{|l,r| r.created_at <=> l.created_at}.select{|r| cond.(r.name) }
      order[:recent] = tmp.sort{|l,r| r.updated_at <=> l.updated_at }.take(ITEM_UPDATED)

      order
    end

    def fetch_and_pull_repositories

      require_relative "utils/git"
      cache = Blog::Fetch.fetch_repos(GIT_HOSTS)

      print "Pull/Clone (a)ll, (n)ot all repositories? (e)xit >>"

      if (input = "#{gets.chomp}n") !~ /^e/i then

        Blog::Fetch.index_model(cache, COND)[:repos].each{|repo|
          
          unless input[0] == ?a
            print "Pull/Clone #{repo.name}? [y/n] >>" 
            next if "#{gets.chomp}n"[0] == ?n
          end
          
          if File.exist?(r_dir = REPOS_ROOT + "/#{repo.name}") then
            puts "\npull #{repo.name} in #{r_dir}"
            Blog::Git.run_git_cmd("pull", dir: r_dir)
          else
            puts "\nclone #{repo.clone_url}"
            Blog::Git.run_git_cmd("clone #{repo.clone_url}", dir: REPOS_ROOT)
          end
        }

      end

      puts "\nFinished"    
    end

  end
end
