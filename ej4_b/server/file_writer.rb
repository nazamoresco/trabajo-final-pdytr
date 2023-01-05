class FileWriter
  def initialize(file_parts)
    @file_parts = file_parts
  end

  def each_item
    return enum_for(:each_item) unless block_given?
    begin
      @file_parts.each do |file_part|
        file = File.open("files/#{file_part.fileName}", "a")
        file << file_part.contentBytes

        yield FileService::FileWriteResponse.new(
          bytesQuantity: file_part.bytesQuantity
        )
      end
    rescue => e
      fail e # signal completion via an error
    end
  end
end
