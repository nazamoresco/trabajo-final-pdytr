this_dir = __dir__
lib_dir = File.join(this_dir, "lib")
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require "grpc"
require "email_services_pb"

class EmailServer < Email::Emailer::Service
  def send_email(email_req, _unused_call)
    exit

    # rubocop:disable Lint/UnreachableCode
    Email::EmailReply.new(success: true, message: "Your email was store successfully")
    # rubocop:enable Lint/UnreachableCode
  end
end

server = GRPC::RpcServer.new
server.add_http2_port("0.0.0.0:50051", :this_port_is_insecure)
server.handle(EmailServer)
server.run_till_terminated_or_interrupted([1, "int", "SIGTERM"])
