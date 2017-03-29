require 'em-websocket'

def websocket_server(address, port)

  Thread.new{
    EM::WebSocket.start(host: address, port: port) do |ws|
      ws.onopen do
      end

      we.onmessage do |msg|
      end

      we.onclose do
      end
    end
  }

end
