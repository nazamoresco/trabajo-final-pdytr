
class FileReader
  # @param [Area] area
  def initialize(request, max_bytes:)
    @request = request
    @max_bytes = max_bytes
  end

  def each
    return enum_for(:each) unless block_given?

    file = File.open("files/" + @request.fileName, "r")
    file.seek(@request.fileOffset)

    total_bytes_to_read = [file.size, @request.bytesQuantity].min
    
    complete_chunks = total_bytes_to_read / @max_bytes
    remaining_chunk_bytes = total_bytes_to_read % @max_bytes

    bytes_chunks = ([@max_bytes] * complete_chunks) 
    bytes_chunks << remaining_chunk_bytes if remaining_chunk_bytes != 0

    bytes_chunks.each do |bytes_to_read|
      yield FileService::FileReadResponse.new(
        contentBytes: file.read(bytes_to_read),
        bytesQuantity: bytes_to_read
      )
    end
  end
end
