this_dir = File.expand_path(File.dirname(__FILE__))
lib_dir = File.join(this_dir, 'lib')
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require 'grpc'
require 'file_service_services_pb'
require_relative "client/id_sender"

hostname = 'localhost:50051'
stub = FileService::FileTransferService::Stub.new(hostname, :this_channel_is_insecure)

stub.write(
  IdSender.new(Random.rand(100)).each_item
) do |response|
  next
end