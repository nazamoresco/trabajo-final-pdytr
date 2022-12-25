```
4)  Con la finalidad de contar con una versión muy restringida de un sistema de archivos remoto, en el cual se puedan llevar a cabo las operaciones enunciadas informalmente como

●Leer: dado un nombre de archivo, una posición y una cantidad de bytes a leer, retorna 1) los bytes efectivamente leídos desde la posición pedida y la cantidad pedida en caso de ser posible, y 2) la cantidad de bytes que efectivamente se retornan leídos

●Escribir: dado un nombre de archivo, una cantidad de bytes determinada, y un buffer a partir del cual están los datos, se escriben los datos en el archivo dado. Si el archivo existe, los datos se agregan al final, si el archivo no existe, se crea y se le escriben los datos. En todos los casos se retorna la cantidad de bytes escritos.

a) Defina e implemente con gRPC un servidor. Documente todas las decisiones tomadas.
```

## Lectura

Para la lectura, se decidió implementar un servicio Server Streaming GRPC, ya que de está forma el servidor puede mandarle el archivo particionado al cliente a través del stream.

Se definicio el servicio de la siguiente forma:

```proto
message FileReadRequest {
  string fileName = 1;
  int32 fileOffset = 2;
  int32 bytesQuantity = 3;
}

message FileReadResponse {
  int32 bytesQuantity = 1;
  bytes contentBytes = 2;
}


service FileTransferService {
  rpc read(FileReadRequest) returns (stream FileReadResponse) {}
}
```


Veamos a continuacion como se construyo el server:

Se obtuvo que el limite para la comunicaciones son 4.194.308 bytes.
```
{UNKNOWN:Error received from peer localhost:50051 {created_time:"2022-12-24T18:06:36.556774716+00:00", grpc_status:8, grpc_message:"Received message larger than max (500000008 vs. 4194304)"}}
```

Se usó este límite menos 4 bytes de bytesQuantity como el máximo de bytes del archivo que se pueden enviar en cada comunicación del stream.
```ruby
class FileServer < FileService::FileTransferService::Service
  MAX_BYTES = 4_194_304

  def read(file_read_req, _unused_call)
    return FileReader.new(file_read_req, max_bytes: MAX_BYTES).each
  end
end
```

La clase se encarga de construir las distintas particiones leidas del archivo.

En el metodo `file_parts` se observa la logica para el leido: 
1. Se abre el archivo bajo la carpeta `/files` (para evitar leer archivos del codigo)
2. Se mueve el puntero del archivo segun el offset.
3. Se calcula la cantidad de bytes a leer y se calcula el tamaño de los distintos *chunks* resultantes.
4. Se lee las particiones construyendo los resultados y se retorna.
```ruby
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
```

El codigo en el cliente es mas sencillo:

Podemos observar como se hace el request, luego se abre un archivo copia, y por cada resultado se añade al archivo.
El resultado es una copia directa del archivo del servidor.
```ruby
stub = FileService::FileTransferService::Stub.new(hostname, :this_channel_is_insecure)
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
```