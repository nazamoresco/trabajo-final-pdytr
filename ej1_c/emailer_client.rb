this_dir = __dir__
lib_dir = File.join(this_dir, "lib")
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require "grpc"
require "email_services_pb"

def request
  hostname = "localhost:50051"
  stub = Email::Emailer::Stub.new(hostname, :this_channel_is_insecure, timeout: 4.955)
  email = Email::EmailRequest.new(title: "Greetings", body: "Greetings from WC champion Argentina.")
  stub.send_email(email)

  puts "Success"
rescue GRPC::BadStatus => e
  puts "ERROR: #{e.message}"
end

10.times { request }
