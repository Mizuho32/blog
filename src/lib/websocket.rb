require 'em-websocket'

def embryo(websocket, id = nil, &task)
  pid = id || rand(100)
  websocket[:connection][pid] = nil
  websocket[:process][pid] = Thread.new{
    task.()
    while not websocket[:connection][pid] do; end
    websocket[:connection][pid].send("dead")
  }
  return pid
end

def websocket_server(address, port)
  
  server = {
    :port => port,
    :server =>
    Thread.start{
      begin
        EM::WebSocket.start(host: address, port: port) do |ws|
          ws.onopen do
            puts "open"
          end

          ws.onmessage do |msg|
            puts "client loaded"
            pid = msg.to_i
            server[:connection][pid] = ws
            ws.send(server[:process][pid]&.status)
          end

          ws.onclose do
          end
        end
      rescue Exception => ex
        puts ex.message, ex.backtrace
      end
    },

    :process => {},
    :connection => {}
  }

end

def wsonly(opt)

  ad,p = (opt[?w] || "localhost:4500").split(?:)
  websocket = websocket_server(ad, p.to_i)

  trap(:INT){
    websocket[:server].kill
  }

  websocket[:server].join

end
