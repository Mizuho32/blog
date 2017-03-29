require 'webrick'
require 'regexp-examples'

def webserver(root_path, address, port)
  #pp WEBrick::HTTPUtils::DefaultMimeTypes
  #pp Hash[(a=FTYPES_RAW.map(&:examples).flatten).zip(%w[text/plain]*a.size)]
  #exit 1
  server = WEBrick::HTTPServer.new({
    :BindAddress => address,
    :Port => port,
    :DocumentROot => root_path,
    :MimeTypes => WEBrick::HTTPUtils::DefaultMimeTypes.merge(
      Hash[(a=FTYPES_RAW.map(&:examples).flatten).zip(%w[text/plain]*a.size)]
    )
  })

  server.mount_proc('/') do |req, res|
    
    #pp req, res
    #pp req.path
    #pp req.header

    filename = File.join(root_path, req.path)

    if File.exist?(html = filename + ".html") then
      pp "HTML", filename
      open(html) do |file|
        res.body = file.read
      end
      res.content_length = File.stat(html).size
      res.content_type = "text/html"
      next
    end

    pp req.path, filename

    if File.directory?(filename) || File.basename(req.path) =~ /^.+\.\w+$/ then
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


def launch(opt)

  ad,p = (opt[?p] || "localhost:4000").split(?:)
  webserver = webserver(File.expand_path(opt[?s] || Dir.pwd), ad, p.to_i)

  trap(:INT){
    webserver.shutdown
  }

  webserver.start
end

