```
2) Describir y analizar los tipos de API que tiene gRPC. Desarrolle una conclusión
acerca de cuál es la mejor opción para los siguientes escenarios:
a) Un sistema de pub/sub
b) Un sistema de archivos FTP
c) Un sistema de chat
```

gRPC te permite la creación de 4 tipos de service methods:

## 1 - Unary RPCs 

Donde el cliente envia una sola petición al servidor y obtiene una única respuesta, como una función común y corriente.

```proto
service Service {
  rpc SayHello(HelloRequest) returns (HelloResponse);
}
```

## 2 - Server streaming RPCs 

Donde el cliente envía una petición al servidor y obtiene un stream para leer una secuencia de mensajes. El cliente lee del stream retornado hasta que no quedan mensajes en el. gRPC garantiza el orden de los mensajes en una llamada RPC.

```proto
service Service {
  rpc LotsOfReplies(HelloRequest) returns (stream HelloResponse);
}
```

## 3 - Client streaming RPCs 

Donde el cliente escribe una secuencia de mensajes y las envía al servidor, usando un stream proveído por el servidor. Una vez el cliente ha terminado de escribir sus mensajes, espera al servidor para que los lea y responda. gRPC garantiza una vez más el orden de los mensajes.

```proto
service Service {
  rpc LotsOfGreetings(stream HelloRequest) returns (HelloResponse);
}
```

## 4 - Bidirectional streaming RPCs 

Donde los dos lados envían una secuencia de mensajes usando un stream de lectura/escritura. Dos streams operan independientemente, así clientes y servidores pueden leer y escribir en el orden que quieran: por ejemplo, el servidor puede esperar a recibir todos los mensajes del cliente antes de escribir sus respuesta. El orden de los mensajes es preservado por gRPC.

```proto
service Service {
  rpc BidiHello(stream HelloRequest) returns (stream HelloResponse);
}
```

## Sistema pub/sub

Para el sistema de pub/sub se podrían tener 2 APIs, una para el publicador y una para los suscriptores.
Los publicadores utilizarían una API “Client Streaming RPC” para poder enviar sus mensajes al servidor."
Los suscriptores utilizarían una API “Server Streaming RPC” para poder escuchar al stream del servidor relacionada al stream del publicador.

## Sistema de archivos

Para el sistema de archivos lo más indicado es usar una combinación, ya que cada método se ajusta mejor a un tipo de servicio distinto. Por ejemplo, para escribir un archivo en el servidor sería interesante un “Client Streaming RPC”, para leer un archivo del servidor un “Server Streaming RPC”, y para navegar entre directorios un “Unary RPC”.

## Sistema de chat

Para un sistema de chat en tiempo real sería interesante un “Bidirectional streaming RPC”, ya que como clientes desean escribir múltiples mensajes al servidor mientras reciben múltiples mensajes del servidor (que a su vez serán mensajes enviados al servidor por otro cliente).
