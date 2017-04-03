require 'erb'
require 'yaml'
require 'fileutils'

require_relative 'utils/git'
require_relative 'utils/util'

include Blog

def string_to_regexp(str)
  return str if Regexp === str
if str =~ %r{^/.*/[a-z]*$} then
    YAML.load("!ruby/regexp #{str}")
  else
    return /.+/ if str.empty?
    Regexp.new(str)
  end

end


def search(pat, repos, branch_pat, breadth, file_pat)
  result = { langs:{} }
  if breadth then
    r = repos
      .inject({}){|ret, repo|
        Dir.chdir("#{REPOS_ROOT}/#{repo}")
        ret[repo] = Git.remote_branch
          .select{|b| b =~ branch_pat }
          .inject({}){|branches, b|
            tmp = Git.grep(pat.source, b)
            tmp.select!{|filename, code|
              file_pat =~ filename
            } unless file_pat.nil?
            tmp.keys.each{|filename|
              result[:langs][filename] =
                Util.filename_to_lang(filename)[:lang] || 
                Util.shebang_to_lang(Git.shebang(filename, repo, b))
            }
            branches[b] = tmp
            branches
          }
        ret
      }
    result[:code]    = r
    result[:pattern] = pat
    result[:breadth] = breadth
    return result
  else
    return {}
  end
end

def split_line_and_code(raw)
  split = raw.scan( %r{^((?:--|\d+))[:-]?($|.+$)} ).transpose
  line = split.first.join("\n")
  code = split.last.join("\n")
  return line, code
end

def result_content(result, page_num)
  eval(
    ERB.new(
      File.read(PROJ_ROOT + "/templ/search_content.erb"), 
      binding, 
      ?-
    ).src
  )
end

def unused_cache_id
  Util.unused_num(Dir.glob(SEARCH_CACHE_ROOT + "/*").map{|n| n.to_i }.sort)
end
def empty_pattern
  id = unused_cache_id

  FileUtils.touch(SEARCH_CACHE_ROOT + "/#{id}")

  headerpart = eval(
    ERB.new(
      File.read(PROJ_ROOT + "/templ/common/docinfo.erb"),
      binding,
      ?-
    ).src
  )
    
  eval(
    ERB.new(
      File.read(PROJ_ROOT + "/templ/search_pat_empty.erb"),
      binding, 
      ?-
 ).src)
end

def generate_search_page(cgi)
  
  return empty_pattern() if cgi["pattern"].empty?

  pat         = string_to_regexp(cgi["pattern"])
  repo_pat    = string_to_regexp(cgi["repository"])
  branch_pat  = string_to_regexp(cgi["branch"])
  breadth     = cgi["breadth"]
  file        = ((!cgi["file"].empty?) and string_to_regexp(cgi["file"])) || nil
  id          = if (i=cgi["id"]).empty? then
                  unused_cache_id
                else
                  i
                end
  repos = YAML.load_file(REPOS_ROOT + "/order.yaml").keys.select{|repo| repo =~ repo_pat }

  result = search(pat, repos, branch_pat, breadth, file)
  $debug.puts result[:langs]
  File.write(SEARCH_CACHE_ROOT + "/#{id}", result.to_yaml)

  headerpart = eval(
    ERB.new(
      File.read(PROJ_ROOT + "/templ/common/docinfo.erb"),
      binding,
      ?-
    ).src
  )

  content = result_content(result, 1)
  eval(
    ERB.new(
      File.read(PROJ_ROOT + "/templ/search_result.erb"),
      binding, 
      ?-
   ).src)
end
