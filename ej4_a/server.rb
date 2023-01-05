this_dir = __dir__
lib_dir = File.join(this_dir, "lib")
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require "grpc"
require "file_service_services_pb"
require_relative "server/file_reader"
require_relative "server/file_writer"

class FileServer < FileService::FileTransferService::Service
  MAX_BYTES = 4_194_304

  def read(file_read_req, _unused_call)
    FileReader.new(file_read_req, max_bytes: MAX_BYTES).each
  end

  def write(file_parts)
    FileWriter.new(file_parts).each_item
  end
end

server = GRPC::RpcServer.new
server.add_http2_port("0.0.0.0:50051", :this_port_is_insecure)
server.handle(FileServer)
server.run_till_terminated_or_interrupted([1, "int", "SIGTERM"])
