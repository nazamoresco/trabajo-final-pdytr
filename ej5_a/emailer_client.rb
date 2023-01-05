this_dir = __dir__
lib_dir = File.join(this_dir, "lib")
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require "grpc"
require "email_services_pb"
require "benchmark"

hostname = "localhost:50051"
stub = Email::Emailer::Stub.new(hostname, :this_channel_is_insecure)
email = Email::EmailRequest.new(title: "Greetings", body: "Greetings from WC champion Argentina.")

n = 100
real_times = n.times.map do
  Benchmark.measure { stub.send_email(email) }.real * 1000.0
end

total_time = real_times.sum
average = total_time / n
standard_deviation = Math.sqrt(real_times.sum { |real_time| (real_time - average)**2 } / (n - 1))

puts "Total time: #{total_time.round(3)} ms"
puts "Average: #{average.round(3)} ms"
puts "Standard deviation: #{standard_deviation.round(3)} ms"
