class FileReader
  MAX_BYTES = 4_194_308
  
  def initialize(file_name)
    @file_name = file_name
  end

  def each_item
    return enum_for(:each_item) unless block_given?

    file = File.open("files/" + @file_name, "r")

    max_bytes = MAX_BYTES - 4 - @file_name.length

    total_bytes_to_read = file.size

    complete_chunks = total_bytes_to_read / max_bytes
    remaining_chunk_bytes = total_bytes_to_read % max_bytes

    bytes_chunks = ([max_bytes] * complete_chunks) 
    bytes_chunks << remaining_chunk_bytes if remaining_chunk_bytes != 0
    
    bytes_chunks.each do |bytes_to_read|
      yield FileService::FileWriteRequest.new(
        fileName: @file_name,
        contentBytes: file.read(bytes_to_read),
        bytesQuantity: bytes_to_read
      )
    end
  end
end
