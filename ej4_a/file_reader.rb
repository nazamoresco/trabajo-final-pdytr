
class FileReader
  # @param [Area] area
  def initialize(request, max_bytes:)
    @request = request
    @max_bytes = max_bytes
  end

  def each
    return enum_for(:each) unless block_given?

    file_parts.each do |location|
      yield location
    end

    puts "Termino el servidor"
  end

  private

  def file_parts
    return @file_parts if defined?(@file_parts)

    file = File.open("files/" + @request.fileName, "r")
    file.seek(@request.fileOffset)

    total_bytes_to_read = [file.size, @request.bytesQuantity].min
    
    complete_chunks = total_bytes_to_read / @max_bytes
    remaining_chunk_bytes = total_bytes_to_read % @max_bytes

    bytes_chunks = ([@max_bytes] * complete_chunks) 
    bytes_chunks << remaining_chunk_bytes if remaining_chunk_bytes != 0

    result = bytes_chunks.map do |bytes_to_read|
      FileService::FileReadResponse.new(
        contentBytes: file.read(bytes_to_read),
        bytesQuantity: bytes_to_read
      )
    end

    @file_parts = result
    @file_parts
  end
end
