require 'yaml'

require 'asciidoctor'
require 'asciidoctor/extensions'

def repo_name_and_relative_path(path, proj_path)
  fullpath = File.expand_path(path)

  if fullpath.include?(proj_path + "/repos") then
    path.sub(proj_path, "") =~ /repos\/([^\/]+)\/?(?:(.+))?$/
    return $1, ($2||"./")
  else
    path =~ /([^\/]+)\/?(?:(.+))?$/
    return $1, ($2||"./")
  end
end

def repo_name(path, proj_path)
  if path.include? proj_path then
    path.sub(proj_path, "")[/repos\/([^\/]+)\//, 1]
  else
    path[/([^\/]+)\//, 1]
  end
end

def remote_branch
  result = Open3.capture3("git branch -r --no-color")
  return [] unless result.last.exitstatus.zero?
  result
    .first
    .split("\n")
    .select{|b| !b.include?("/HEAD")}
    .map{|b| b[/^[^\/]+\/([^\/]+)/, 1]}
end

def remote_branch?(name)
  if (result = Open3.capture3("git branch -r --no-color")).last.exitstatus.zero? then
    if result.first.include? name then
      result.first.split("\n")
        .select{|b| b.include?(name)&& !b.include?("/HEAD")}
        .first
        .strip
    else
      false
    end
  else
    #STDERR.puts result[1]
    false
  end
end

def local_branch?(name)
  if (result = Open3.capture3("git branch --no-color")).last.exitstatus.zero? then
    return name if result.first.include? name
  else
    #STDERR.puts result[1]
    false
  end
end 

def commit_hash?(hash, is_branch)
  if (result = Open3.capture3("git cat-file -e #{hash}^{commit}")).last.exitstatus.zero? then
    return hash if !is_branch
  else
    #STDERR.puts result[1]
  end
  false
end 

def current_branch?(name=nil)
  res = Open3.capture3("git symbolic-ref --short HEAD")
  unless res.last.exitstatus.zero? then
    STDERR.puts res[1]
    return false
  end

  if name.nil? then
    res.first.strip
  else
    res.first.strip == name
  end
end

def file_exists?(gitrev, path)
  res = Open3.capture3("git show #{gitrev}:#{path} > /dev/null")
  unless res.last.exitstatus.zero? then
    #STDERR.puts res[1]
    return false
  end

  true
end

def file_type?(path)
  `file -b -i #{path}`.strip
end

def generate_dir_index(repo_name, rel_path, rev)
  ftypes = (tmp=YAML.load_file(PROJ_ROOT + "/conf/ftypes.yaml"))[:doc].merge(tmp[:code]).keys
  path = File.expand_path(PROJ_ROOT + "/articles/#{repo_name}/#{rev}/#{rel_path}")
  files = `git show #{rev}:#{rel_path}`.split("\n")[2..-1]

  # make dir for non binary files
  files = files.select{|file| 
    filepath = "#{path}/#{file}"

    next(true)  if File.directory?(filepath)
    next(false) if File.exist?(filepath)

    # not dir nor code nor doc, looks binary
    unless file[-1] != ?/ && ftypes.any?{|t| t =~ file} then  
      now = Time.now
      tmpfile = "#{path}/#{now.hour}#{now.min}#{now.sec}"
      `git show #{rev}:#{rel_path}/#{file} > #{tmpfile}`

      if file_type?(tmpfile)[0] != ?t then # binary
        FileUtils.mv(tmpfile, "#{path}/#{file}")
        next(false)
      else
        FileUtils.mkdir_p(filepath)
        FileUtils.mv(tmpfile, "#{path}/#{file}/#{file}")
      end
    end
    FileUtils.mkdir_p(filepath)
    true
  }

  # index.html under repository
  if rel_path.empty? then
    relcss = Pathname(PROJ_ROOT + "/articles/css").relative_path_from(Pathname(PROJ_ROOT + "/articles/#{repo_name}")).to_s
    adoc = <<-"ADOC"
= #{repo_name}

#{ 
remote_branch.map{|b| 
  "link:/#{"#{repo_name}/#{b}".gsub(/\/+/,?/)}[#{b}]::"
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

  # index.html under dir
  relcss = Pathname(PROJ_ROOT + "/articles/css").relative_path_from(Pathname(path)).to_s
  adoc = <<-"ADOC"
= #{repo_name}/#{rev}

#{
  files
  .map{|file| 
    "link:/#{"#{repo_name}/#{rev}/#{rel_path}/#{file}".gsub(/\/+/,?/)}[#{file}]::"
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

def fortext(write_path, lang)
  basename = File.basename(write_path)
  dir = File.dirname(write_path)

  title = File.basename(write_path)
  asciidoctorcss = Pathname(PROJ_ROOT + "/articles/css").relative_path_from(Pathname(dir)).to_s
  code_title = title
  code = File.read(write_path)
  highlightjs = Pathname(PROJ_ROOT + "/articles/highlight").relative_path_from(Pathname(dir)).to_s
  style = "github"
  
  html = eval(ERB.new(File.read(PROJ_ROOT + "/templ/codeview.erb"), binding, ?-).src)
  #puts title, asciidoctorcss, code_title, highlightjs
  File.write(dir + "/index.html", html)
end

def shebang_to_lang(line)
  line =~ /^#!(?:\/[^\/]+)+?\/([^\/\s]+)(?:$|\s+)(\w+)?/i
  $2 || $1
end

def guess_lang(file_path)
  File.open(file_path){|file|
    shebang_to_lang(file.readline)
  }
end

def forbinary(type)
end

def generate_file_index(repo_name, rel_path, rev, write_path, type)
  ftypes = YAML.load_file(PROJ_ROOT + "/conf/ftypes.yaml") 
  if type[0] == ?t then # text
    # file type (code? doc?) and format (lang)
    result = ftypes
      .inject({}){|result, (type, langs)| 
        if l = (langs.select{|pat, la|
          pat =~ write_path
        }.values.first) then
          result[:type] = type
          result[:lang] = l
        end
        result
      }
    if result[:type] == :doc then
      generate_doc(write_path, result[:lang])
    else
      fortext(write_path, result[:lang] || guess_lang(write_path))
    end
  else
    forbinary(type)
  end
end

def generate_html(repo_name, rel_path, type, rev)
  #rel_path = File.expand_path("#{rel_path}", ?/)[1..-1]

  if type =~ %r{inode/directory} then
    generate_dir_index(repo_name, rel_path, rev)
  else
    # file
    write_path = PROJ_ROOT + "/articles/#{repo_name}/#{rev}/#{rel_path}/#{File.basename(rel_path)}"

    generate_html(repo_name, rel_path, "inode/directory", rev) unless File.exist?(File.dirname(write_path))
    `git show #{rev}:#{rel_path} > #{write_path}` unless File.exist?(write_path)
    #pp "#{write_path}"
    generate_file_index(repo_name, rel_path, rev, write_path, type)
  end
end

def generate_page(path, rev)

  # get revision or branch and relative path
  branch_or_rev = rev || "master"
  repo_name, rel_path = repo_name_and_relative_path(path, PROJ_ROOT)

  #pp path, branch_or_rev
  pp repo_name, rel_path

  # branch or revision exists?
  Dir::chdir(PROJ_ROOT + "/repos/#{repo_name}")
  branch = local_branch?(branch_or_rev) || (remote = remote_branch?(branch_or_rev))
  result = branch || commit_hash?(branch_or_rev, branch)

  unless result then
    STDERR.puts %Q{No branch nor revision "#{branch_or_rev}". Abort}
    exit 1
  end

  unless file_exists?(result, rel_path)
    STDERR.puts %Q{#{rel_path} doesnt exist in "#{branch_or_rev}". Abort}
    exit 1
  end

  # checkout 
  # fixme?
  if remote then
    system "git checkout -b #{branch_or_rev} #{remote}"
  elsif branch
    system "git checkout #{result}" unless current_branch?(result)
  else
    system "git checkout #{result}"
  end

  pp type = file_type?("#{PROJ_ROOT}/repos/#{repo_name}/#{rel_path}")

  generate_html(repo_name, rel_path, type, branch_or_rev)

end
