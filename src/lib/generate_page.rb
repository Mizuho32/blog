require 'yaml'
require 'cgi'

require 'asciidoctor'
require 'asciidoctor/extensions'

require_relative 'utils/path_and_file'
require_relative 'utils/git'
require_relative 'utils/util'

include Blog
$debug = STDOUT

def generate_docinfo_for_index(current, branches, repo_name, rel_path)
branch_dropdown_css = '''
    form {
      display: inline-block;
    }
    .dropbtn {
      background-color: #4CAF50;
      color: white;
      /*padding: 16px;*/
      font-size: 16px;
      border: none;
      cursor: pointer;
    }
    .branch-dropdown {
      position: relative;
      display: inline-block;
      float: right;
    }
    .branch-dropdown.content {
      display: none;
      position: absolute;
      background-color: #f9f9f9;
      min-width: 160px;
      box-shadow: 0px 8px 16px 0px rgba(0,0,0,0.2);
      z-index: 1;
      right: 0;
    }
    .branch-dropdown.content a {
        color: black;
        padding: 12px 16px;
        text-decoration: none;
        display: block;
    }
    .branch-dropdown:hover .branch-dropdown.content {
      display: block;
    }
'''

branch_dropdown_html = <<-"HTML"
    <div class="branch-dropdown">
      <button class="dropbtn">#{current}</button>
      <div class="branch-dropdown content">
#{
          branches.map{|b| 
%Q{        <a href="#{Pathname("/#{repo_name}/#{b}/#{rel_path}").cleanpath}">#{b}</a>}
          }.join("\n")
        }
      </div>
    </div>
HTML
  cgi = {} #dummy fixme
  Util.render_erb(PROJ_ROOT + "/templ/common/docinfo.erb", binding)
end

def generate_dir_index(repo_name, rel_path, rev)

  ftypes = FTYPES[:doc].merge(FTYPES[:code]).keys
  path = File.expand_path(ART_ROOT + "/#{repo_name}/#{rev}/#{rel_path}")
  files = Git.ls(rel_path, rev)
  index_html_included = false

  # make dir for non binary files
  files.each{|file| 
    filepath = "#{path}/#{file}"
    
    if file[-1] == ?/ then # file on git repo is dir
      FileUtils.mkdir_p filepath
      #$debug.puts "mkdir #{filepath}"
      next
    end
    next if File.directory?(filepath)  # dir exists

    # not dir nor code nor doc, looks binary
    unless  ftypes.any?{|t| t =~ file} then  
      now = Time.now
      #fixme
      tmpfile = "#{path}/#{now.hour}#{now.min}#{now.sec}"
      `git show #{rev.revision}:#{rel_path}/#{file} > "#{tmpfile}"`

      if Util.file_type?(tmpfile)[0] != ?t then # binary
        #$debug.puts "binary:#{file}   #{path}/#{file}"
        FileUtils.mv(tmpfile, "#{path}/#{file}")
      elsif file =~ /\.html$/ then # html file # fixme
        index_html_included = true if file == "index.html"
        FileUtils.mv(tmpfile, "#{path}/#{file}")
      else  # text
        #$debug.puts "text:#{file}   #{path}/#{file}/#{file}"
        FileUtils.mkdir_p(filepath)
        FileUtils.mv(tmpfile, "#{path}/#{file}/#{file}")
      end

      next
    end
    FileUtils.mkdir_p(filepath)
  }
  
  return if index_html_included
  branches = Git.remote_branch

  # fixme?
  # index.html under repository root page
  if rel_path == "./" then
    relcss = Pathname(PROJ_ROOT + "/articles/css").relative_path_from(Pathname(PROJ_ROOT + "/articles/#{repo_name}")).to_s
    adoc = <<-"ADOC"
= #{repo_name}

#{ 
(branches).map{|b| 
  "link:#{b}/[#{b}]::"
}
.join("\n") 
}
ADOC
    html = Asciidoctor.convert(
      adoc,
      safe: :unsafe,
      header_footer: true,
      attributes: {
      'linkcss'    => "",
      'stylesdir'  => relcss,
      'docinfodir' => (PROJ_ROOT + "/templ/common"), 
      'docinfo'    => "shared"
      }
    )
    File.write(PROJ_ROOT + "/articles/#{repo_name}/index.html", html)
  end

  # gen docinfo for index
  File.write(CACHE_ROOT + "/index/docinfo.html", generate_docinfo_for_index(rev, branches, repo_name, rel_path))

  # index.html under dir
  relcss = Pathname(PROJ_ROOT + "/articles/css").relative_path_from(Pathname(path)).to_s
  adoc = <<-"ADOC"
= #{repo_name}/#{rev}

#{
  files
  .map{|file| 
    "link:#{file}[#{file}]::"
  }
  .join("\n") 
}
ADOC
  html = Asciidoctor.convert(
    adoc,
    safe: :unsafe,
    header_footer: true,
    attributes: {
    'linkcss'    => "",
    'stylesdir'  => relcss,
    'docinfodir' => (CACHE_ROOT + "/index"), 
    'docinfo'    => "shared"
    },
  )
  File.write(path + "/index.html", html)
end

def generate_doc(write_path, lang)
  begin
    require_relative "gendocs/#{lang}"
    Blog::DocRenderer.send(lang, write_path)
  rescue LoadError => ex
    STDERR.puts "script for rendering #{lang} not found in #{PROJ_ROOT + "/src/lib/gendocs"}"
  end
end

# text but not document
def fortext(write_path, lang)
  basename = File.basename(write_path)
  dir = File.dirname(write_path)

  title = File.basename(write_path)
  asciidoctorcss = Pathname(PROJ_ROOT + "/articles/css").relative_path_from(Pathname(dir)).to_s
  code_title = title
  code = CGI.escapeHTML(File.read(write_path))
  puts code
  highlightjs = Pathname(PROJ_ROOT + "/articles/highlight").relative_path_from(Pathname(dir)).to_s
  style = "github"
  
  html = eval(ERB.new(File.read(PROJ_ROOT + "/templ/codeview.erb"), binding, ?-).src)
  #puts title, asciidoctorcss, code_title, highlightjs
  File.write(dir + "/index.html", html)
end


def forbinary(type)
end

def generate_file_index(repo_name, rel_path, rev, write_path)

  # file type (code? doc?) and format (lang)
  result = FTYPES
    .inject({}){|result, (type, langs)| 
      if l = (langs.select{|pat, la|
        pat =~ write_path
      }.values.first) then
        result[:type] = type
        result[:lang] = l
      end
      result
    }
  
  generate_doc(write_path, result[:lang]) if result[:type] == :doc
  fortext(write_path, result[:lang] || Util.guess_lang(write_path))
end

def generate_html(repo_name, rel_path, is_dir, rev)

  d = ART_ROOT + "/#{repo_name}/#{rev}/#{rel_path}"

  if is_dir then
    FileUtils.mkdir_p(d) unless File.exist?(d)
    generate_dir_index(repo_name, rel_path, rev)
  else
    write_path = ART_ROOT + "/#{repo_name}/#{rev}/#{rel_path}/#{File.basename(rel_path)}"

    pp "generate_html", rel_path
    generate_html(repo_name, Git.dirname(rel_path), true, rev) unless File.exist?(File.dirname(write_path))

    if File.exist?(d) and not File.directory?(d) then # binary
      $debug.puts "binary. exit"
      return
    end

    # ~~ Text only ~~
    #fixme
    `git show #{rev.revision}:#{rel_path} > "#{write_path}"` unless File.exist?(write_path)
    #pp "#{write_path}"
    generate_file_index(repo_name, rel_path, rev, write_path)
  end
end

# rev: raw revision or branch string
def valid_path?(path, rev)

  # get revision or branch and relative path
  branch_or_rev = rev&.strip || "master"
  repo_name, rel_path = Util.repo_name_and_relative_path(path.gsub(/\/+/,?/), REPOS_ROOT)

  ## ERROR CHECK ##
  unless File.directory?(REPOS_ROOT + "/#{repo_name}") then
    STDERR.puts %Q{No repository "#{repo_name}". Abort}
    return false
  end

  #pp path, branch_or_rev
  #pp repo_name, rel_path
  $debug.puts("name:#{repo_name}, rel_path:#{rel_path}, rev:#{branch_or_rev}")

  # branch or revision exists?
  Dir::chdir(REPOS_ROOT + "/#{repo_name}")

  #branch = Git.remote_branch?(branch_or_rev)
  #result = Git.commit_hash?(branch_or_rev, branch) || (branch && "#{GIT_REMOTE}/#{branch}")

  begin
    result = Git::GitRevision.new(branch_or_rev)
  rescue ArgumentError => ex
    STDERR.puts "", ex.message
    STDERR.puts %Q{No branch nor revision "#{branch_or_rev}". Abort}
    return false
  end

  if not Git.exist?(rel_path, result) or rel_path.nil?
    STDERR.puts %Q{#{rel_path} doesnt exist in "#{branch_or_rev}". Abort}
    return false
  end
  
  return [repo_name, rel_path, result]
end

# repo: repository name
# rel:  relative path under repository. rel should pass `git show branch:rel`
# rel can end with no / if it is directory. Auto detect
# rev: raw revision or branch string
def generate_page(repo, rel, rev, skip_check = false)

  repo_name, rel_path, branch_or_rev = if skip_check then
    [repo, rel, rev]
  elsif ret = valid_path?(path, rev) then
    ret
  else
    return ret
    false
  end

  is_dir = Git.directory?(rel_path, branch_or_rev)
  $debug.puts "dir #{is_dir}"
  generate_html(repo_name, rel_path, is_dir, branch_or_rev)

end
