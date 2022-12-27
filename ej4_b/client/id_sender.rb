class IdSender
  MAX_BYTES = 4_194_308
  
  def initialize(id)
    @id = id
  end

  def each_item
    return enum_for(:each_item) unless block_given?
    
    100.times do |idx|
      msg = "Hola, soy #{@id}! Este es mi saludo nro #{idx}.\n"

      yield FileService::FileWriteRequest.new(
        fileName: "file.txt",
        contentBytes: msg,
        bytesQuantity: msg.length
      )
    end
  end
end
