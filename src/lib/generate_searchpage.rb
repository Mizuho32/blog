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

def file_code_content(repo, branch, file_code, id, result, page_num)
  pat         = result[:pattern]
  start_index = (page_num-1)*ITEM_PER_PAGE
  range       = ITEM_PER_PAGE

  file_code.drop(start_index).take(range).map{|file, rawcode|

    line,code = split_line_and_code(rawcode)
    code = CGI.escapeHTML(code.gsub!(%r|(#{pat})|, "\x0\\1\x1"))

    code.gsub!("\x0", '<em class="match">').gsub!("\x1", '</em>')
    <<-"CODE"
  <div class="listingblock">
    <div class="title">
      <a href="#{repo}/#{branch}/#{file}/?pattern=#{CGI.escape(pat.inspect)}" class="bare">#{file}</a>
    </div>
    <div class="content">
      <pre class="highlightjs highlight"><code class="hljs hljs-line-numbers" style="float: left;">#{line}</code><code class="language-#{result[:langs][file]} hljs" data-lang="#{result[:langs][file]}">#{code}</code></pre>
    </div>
  </div>
CODE
  }.join("\n") +
<<-"PAGER"
    <table>
      <tbody>
        <tr>
          <td>
          #{
            1.step(Rational(file_code.size, ITEM_PER_PAGE).ceil).map {|i|
              if page_num == i then
                i.to_s
              else
                <<-"TD"
                  <a class="pager" href="#" repo="#{repo}" branch="#{branch}" sid="#{id}" style="color: #4285f4;">
                    #{i}
                  </a>
                TD
              end
            }.join("\n")
          }
          </td>
        </tr>
      </tbody>
    </table>
    <script src="js/lib/lib.js"></script>
    <script src="js/pager.js"></script>
PAGER
end


def branch_code_content(repo, b_code, id, result, tab_index)
  b_code.each_with_index.map{|(branch, file_code), i|
<<-"DL"
      <div class="branches">
        <input name="branches#{tab_index}" type="radio" id="#{branch}" #{i.zero? ? :checked : ""}>
        <label for="#{branch}">#{branch}</label>
        <div class="branch-content">
          #{
            file_code_content(repo, branch, file_code, id, result, 1)
          }
        </div>
      </div>
DL
  }.join("\n")
end

def result_content(result, id, page_num)
  Util.render_erb(PROJ_ROOT + "/templ/search_content.erb", binding)
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

  if (page_num = cgi["page"].to_i) != 0 then

    result = YAML.load_file(SEARCH_CACHE_ROOT + "/#{id = cgi["id"]}")
    repo = cgi["repository"]
    branch = cgi["branch"]

"""Content-type: text/html


""" + 
    file_code_content(repo, branch, result[:code][repo.to_sym][branch], id, result, page_num)
  else

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

    content = result_content(result, id, 1)
    eval(
      ERB.new(
        File.read(PROJ_ROOT + "/templ/search_result.erb"),
        binding, 
        ?-
     ).src)
  end
end
