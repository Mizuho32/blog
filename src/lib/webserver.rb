def reqpath_to_pathongit(req)
  %r[\A/([^/]+)(?:/([^/]+))?(/.*)?] =~ req.path
  # name ,rev, path
  return $1, $2, ?. + ($3 || "/")
end

def trap404(req, res)

  asciidoctorcss = "/css"
  message = "Not found: " + req.path
  res.status = 404
  res.body = eval(ERB.new(File.read(PROJ_ROOT + "/templ/404.erb"), binding, ?-).src)
  res.content_length = res.body.size
  res.content_type = "text/html"

end

def trap_file_not_exist(req,res)

  repo_name, rev, rel_path = reqpath_to_pathongit(req)
  rel_path.sub!(%r|([^\.])/+$|, '\1')  # hoge/ -> hoge except ./
  pp repo_name, rev, rel_path

  if ret = valid_path?("#{repo_name}/#{rel_path}", rev) then
    generate_page(*ret, true) # fixme rev.nil?
  else
    trap404(req, res)
  end

end

def webserver(root_path, address, port)

  server = WEBrick::HTTPServer.new({
    :BindAddress => address,
    :Port => port,
    :DocumentROot => root_path,
    :MimeTypes => WEBrick::HTTPUtils::DefaultMimeTypes.merge(
      Hash[(a=FTYPES_RAW.map(&:examples).flatten).zip(%w[text/plain]*a.size)]
    )
  })

  server.mount_proc('/') do |req, res|
    
    filename = File.join(root_path, req.path)

    pp req.path, filename

    # dynamic page generation
    if 
      not File.exist?(filename) or 
      (is_dir = File.directory?(filename) and not File.exist?(filename + "/index.html"))
      then

      trap_file_not_exist(req, res)
      next
    end

    if File.exist?(html = filename + ".html") then
      pp "HTML", filename
      open(html) do |file|
        res.body = file.read
      end
      res.content_length = File.stat(html).size
      res.content_type = "text/html"
      next
    end

    if is_dir || File.basename(req.path) =~ /^.+\.\w+$/ then
      pp "FileHandle"
      WEBrick::HTTPServlet::FileHandler
        .new(server, root_path, {:FancyIndexing => true})
        .service(req, res)
    else
      pp "plain text"
     
      open(filename) do |file|
        res.body = file.read
      end
      res.content_length = File.stat(filename).size
      res.content_type = "text/plain"
    end
  end 

  server
end

