require 'webrick'

def webserver(root_path, address, port)

  server = WEBrick::HTTPServer.new({
    :BindAddress => address,
    :Port => port,
    :DocumentROot => root_path
  })

  server.mount_proc('/') do |req, res|
    
    #pp req, res

    filename = File.join(root_path, req.path)

    if File.directory?(filename) || req.path =~ /\.\w+$/ then
      WEBrick::HTTPServlet::FileHandler
        .new(server, root_path, {:FancyIndexing => true})
        .service(req, res)
    else
      open(filename) do |file|
        res.body = file.read
      end
      res.content_length = File.stat(filename).size
      res.content_type = "text/plain"
    end

    #pp res
    #pp req.query_string,req.query, req.path
    #WEBrick::HTTPServlet::FileHandler.
      #new(server, Dir.pwd, {:FancyIndexing => true}).service(req, res)
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

