require 'webrick'

require 'regexp-examples'

require_relative 'generate_page'
require_relative 'webserver'



def launch(opt)

  ad,p = (opt[?p] || "localhost:4000").split(?:)
  webserver = webserver(File.expand_path(opt[?s] || Dir.pwd), ad, p.to_i)

  trap(:INT){
    webserver.shutdown
  }

  webserver.start
end

