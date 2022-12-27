require 'socket'
require 'benchmark'

def request(server)
  server.puts "Title - My email title"
  server.puts "Body - My email body"

  server.gets # Success
  server.gets # Message
end

server = TCPSocket.new 'localhost', 50051

n = 100
real_times = n.times.map do
  Benchmark.measure { request(server) }.real * 1000.0
end

server.close

total_time = real_times.sum
average = total_time / n
standard_deviation = Math.sqrt(real_times.sum { |real_time| (real_time - average) ** 2} / (n - 1)) 

puts "Total time: #{total_time.round(3)} ms"
puts "Average: #{average.round(3)} ms"
puts "Standard deviation: #{standard_deviation.round(3)} ms"