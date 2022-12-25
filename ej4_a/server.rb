this_dir = File.expand_path(File.dirname(__FILE__))
lib_dir = File.join(this_dir, 'lib')
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require 'grpc'
require 'file_service_services_pb'
require_relative 'file_reader'

class FileServer < FileService::FileTransferService::Service
  MAX_BYTES = 4_194_304

  def read(file_read_req, _unused_call)
    return FileReader.new(file_read_req, max_bytes: MAX_BYTES).each
  end
end

server = GRPC::RpcServer.new
server.add_http2_port('0.0.0.0:50051', :this_port_is_insecure)
server.handle(FileServer)
server.run_till_terminated_or_interrupted([1, 'int', 'SIGTERM'])
