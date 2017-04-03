require 'webrick'

require 'regexp-examples'

require_relative 'generate_page'
require_relative 'webserver'
require_relative 'websocket'



def launch(opt)

  ad,p = (opt[?w] || "localhost:4500").split(?:)
  websocket = websocket_server(ad, p.to_i)

  ad,p = (opt[?p] || "localhost:4000").split(?:)
  webserver = webserver(File.expand_path(opt[?s] || Dir.pwd), ad, p.to_i, websocket)

  trap(:INT){
    webserver.shutdown
    websocket[:server].kill
  }

  webserver.start
end
