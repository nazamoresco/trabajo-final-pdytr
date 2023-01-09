# Ejercicio 4B
```
4)  Con la finalidad de contar con una versión muy restringida de un sistema de archivos remoto, en el cual se puedan llevar a cabo las operaciones enunciadas informalmente como

●Leer: dado un nombre de archivo, una posición y una cantidad de bytes a leer, retorna 1) los bytes efectivamente leídos desde la posición pedida y la cantidad pedida en caso de ser posible, y 2) la cantidad de bytes que efectivamente se retornan leídos

●Escribir: dado un nombre de archivo, una cantidad de bytes determinada, y un buffer a partir del cual están los datos, se escriben los datos en el archivo dado. Si el archivo existe, los datos se agregan al final, si el archivo no existe, se crea y se le escriben los datos. En todos los casos se retorna la cantidad de bytes escritos.

b) Investigue si es posible que varias invocaciones remotas estén ejecutándose concurrentemente y si esto es apropiado o no para el servidor de archivos del ejercicio anterior. En caso de que no sea apropiado, analice si es posible proveer una solución (enunciar/describir una solución, no es necesario implementarla).
Nota: diseñe un experimento con el que se pueda demostrar fehacientementeque
dos o más invocaciones remotas se ejecutan concurrentemente o no
```
El ejercicio se desarrolló en la carpeta `ej4_b`.

Es posible, ya que por cada invocación del cliente el servidor creará un nuevo thread, y es apropiado siempre y cuando no se escriba sobre los mismos archivos.

Para demostrar esto se llevará a cabo un experimento.
Se ejecutarán en simultáneo dos clientes que imprimen en un archivo la oración "Hola, soy #{@id}! Este es mi saludo nro #{idx}.\n" múltiples veces.
Si el contenido del archivo posee mensajes intercalados de los distintos clientes podremos asegurar que se ejecutan concurrentemente, en caso contrario no será asegurable.

Para implementar el experimento se modificó el ejercicio anterior de la siguiente forma:

En el cliente se llama a la clase IdSender que envía el mensaje mencionado:
```ruby
stub.write(
  IdSender.new(Random.rand(100)).each_item
) do |response|
  next
end
```

En este archivo se observa como `IdSender` envía 100 saludos al servidor para ser escritos.
```ruby
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
```

En el servidor no es necesario ningún cambio.

Se modificó el docker-compose para levantar dos clientes en vez de uno.

```yml
version: "3"
services:
  server:
    build:
      context: .
      dockerfile: Server
    container_name: ej4_b_server
    ports:
      - 50051:50051
  client_1:
    build:
      context: .
      dockerfile: Client
    container_name: ej4_b_client_1
    network_mode: host
    depends_on: 
      - server
  client_2:
    build:
      context: .
      dockerfile: Client
    container_name: ej4_b_client_2
    network_mode: host
    depends_on: 
      - server
```

Una vez ejecutado el docker-compose con los clientes finalizados el servidor seguirá corriendo, se usó el comando `docker exec -it ej4_b_server bash` para abrir una terminal en el container del servidor.

En este se observó el comienzo del archivo `files/file.txt` donde se confirma la ejecución concurrente.
```bash
root@4885b6733ff0:/server# head files/file.txt
Hola, soy 69! Este es mi saludo nro 24.
Hola, soy 69! Este es mi saludo nro 25.
Hola, soy 30! Este es mi saludo nro 0.
Hola, soy 30! Este es mi saludo nro 1.
Hola, soy 69! Este es mi saludo nro 26.
Hola, soy 69! Este es mi saludo nro 27.
Hola, soy 69! Este es mi saludo nro 28.
Hola, soy 30! Este es mi saludo nro 2.
Hola, soy 69! Este es mi saludo nro 29.
Hola, soy 30! Este es mi saludo nro 3.
```

Idealmente, se evitaría que otros hilos escriban o lean un archivo mientras un hilo lo está escribiendo.
Ese es un problema clásico de exclusión mutua.
Para resolverlo se podría tener un diccionario con variables lock para cada archivo, cuando un hilo quiera escribir sobre un archivo bloqueara está variable y la desbloqueara cuando termine.
Sería necesario también implementar la exclusión mutua para acceder a estas estructuras.

[Siguiente](ej5_a.md)

[Volver](../../README.md)

