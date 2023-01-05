this_dir = __dir__
lib_dir = File.join(this_dir, "lib")
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require "grpc"
require "file_service_services_pb"
require_relative "client/file_reader"

hostname = "localhost:50051"
stub = FileService::FileTransferService::Stub.new(hostname, :this_channel_is_insecure)

puts "Reading"

call = stub.read(FileService::FileReadRequest.new(
  fileName: "image.jpg",
  fileOffset: 0,
  bytesQuantity: 10_000_000
))

File.open("files/image_copy.jpg", "a") do |file|
  call.each do |file_part|
    file << file_part.contentBytes
  end
end

puts "Writing"

stub.write(
  FileReader.new("image.jpg").each_item
) do |response|
  puts "Se han escrito #{response.bytesQuantity}"
end
