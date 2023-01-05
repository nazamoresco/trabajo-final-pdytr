this_dir = __dir__
lib_dir = File.join(this_dir, "lib")
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require "grpc"
require "email_services_pb"
require "benchmark"

def request
  hostname = "localhost:50051"
  stub = Email::Emailer::Stub.new(hostname, :this_channel_is_insecure)
  email = Email::EmailRequest.new(title: "Greetings", body: "Greetings from WC champion Argentina.")
  stub.send_email(email)
end

n = 10
real_time = Benchmark.measure {
  n.times { request }
}.real

puts "Average: #{(real_time / n).round(3)}segs"
