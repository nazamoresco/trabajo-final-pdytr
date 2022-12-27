require 'socket'

server = TCPServer.new 50051 # Server bound to port 50051

loop do
  client = server.accept    # Wait for a client to connect

  100.times do
    client.gets # Title
    client.gets # Body
    client.puts true
    client.puts "Your email is ok."
  end

  client.close
end