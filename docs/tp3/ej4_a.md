```
4)  Con la finalidad de contar con una versión muy restringida de un sistema de archivos remoto, en el cual se puedan llevar a cabo las operaciones enunciadas informalmente como

●Leer: dado un nombre de archivo, una posición y una cantidad de bytes a leer, retorna 1) los bytes efectivamente leídos desde la posición pedida y la cantidad pedida en caso de ser posible, y 2) la cantidad de bytes que efectivamente se retornan leídos

●Escribir: dado un nombre de archivo, una cantidad de bytes determinada, y un buffer a partir del cual están los datos, se escriben los datos en el archivo dado. Si el archivo existe, los datos se agregan al final, si el archivo no existe, se crea y se le escriben los datos. En todos los casos se retorna la cantidad de bytes escritos.

a) Defina e implemente con gRPC un servidor. Documente todas las decisiones tomadas.
```
El ejercicio se desarrolla en la carpeta `ej4_a`.


## Lectura

Para la lectura, se decidió implementar un servicio Server Streaming GRPC, ya que de está forma el servidor puede enviarle el archivo particionado al cliente a través de un stream.

Se definio el servicio de la siguiente forma:
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

A continuacion como se construyo el server:

Primero se obtuvó que el limite para la comunicaciones son 4.194.308 bytes para ruby.
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

La clase `FileReader` se encarga de construir las distintas particiones leidas del archivo.

En el metodo `each` se observa la logica para el leido: 
1. Se abre el archivo bajo la carpeta `/files` (para evitar leer archivos del codigo)
2. Se mueve el puntero del archivo segun el offset.
3. Se calcula la cantidad de bytes a leer y se calcula el tamaño de los distintos *chunks* resultantes.
4. A medida que se lee las particiones se retornan al cliente con la instruccion `yield`
```ruby
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
```

El codigo en el cliente es mas sencillo:

Se puede observar como se hace el request, luego se abre un archivo copia y por cada resultado se añade al archivo.
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

## Escritura

Para la escritura se utilizó un esquema de streaming bidireccional, esto se debe a que el cliente debe ir stremeando el archivo y a su vez, el servidor debe ir devolviendo la cantidad de bytes que escribió. El cliente envía los bytes del archivo más el nombre del archivo a escribir y la cantidad de bytes enviados, el servidor responde con la cantidad de bytes escritos.

```proto
service FileTransferService {
  rpc write(stream FileWriteRequest) returns (stream FileWriteResponse) {}
}

message FileWriteRequest {
  string fileName = 1;
  int32 bytesQuantity = 2;
  bytes contentBytes = 3;
}
 
message FileWriteResponse {
  int32 bytesQuantity = 1;
}
```

En el cliente invocamos a una clase `FileReader` que se encargará construir las partes a enviar al servidor y un bloque que reacciona al stream del servidor. 
```ruby
stub.write(
  FileReader.new("image.jpg").each_item
) do |response|
  puts "Se han escrito #{response.bytesQuantity}"
end
```

El `FileReader` del cliente es similar al del servidor con la diferencia que se envian del cliente al servidor y no del servidor al cliente, y que se tiene que tener en cuenta los caracteres del nombre del archivo para el calculo del maximo de bytes para la comunicacion.
```ruby
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
```


En el servidor se invoca a la clase `FileWriter` que se encarga de escribir el archivo enviado por el cliente.
```ruby
def write(file_parts)
  FileWriter.new(file_parts).each_item
end
```

`FileWriter` es sencillo por cada particion recibida, la escribe y devuelve al cliente los bytes escritos.
```ruby
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
    rescue StandardError => e
      fail e # signal completion via an error
    end
  end
end
```
