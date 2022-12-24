this_dir = File.expand_path(File.dirname(__FILE__))
lib_dir = File.join(this_dir, 'lib')
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require 'grpc'
require 'email_services_pb'

hostname = 'localhost:50051'
stub = Email::Emailer::Stub.new(hostname, :this_channel_is_insecure, timeout: 2)
email = Email::EmailRequest.new(title: "Greetings", body: "Greetings from WC champion Argentina.")
email_response = stub.send_email(email)

puts "The email was successful?: #{email_response.success}, message: #{email_response.message}"