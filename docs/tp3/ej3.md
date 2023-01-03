```
3) Analizar la transparencia de gRPC en cuanto al manejo de parámetros de los procedimientos remotos. Considerar lo que sucede en el caso de los valores de retorno. Puede aprovechar el ejemplo provisto.
```

La transparencia del manejo de parámetros de gRPC se halla en el archivo .proto, ya que gracias a este tanto el cliente como el servidor conocen los mensajes y servicios definidos. Esto implica que ambos conocen los parametros que se pueden enviar o recibir por cada petición o respuesta.

Para contrastar, la transparencia de los parámetros en un API REST tradicional generalmente no existe para el cliente sino que se debe acceder a una documentación para conocer los distintos parámetros y su tipo, en cambio en gRPC se tiene el archivo .proto, escrito en un DSL que genera código necesario para el funcionamiento de la API (“Para Java, el compilador genera un archivo .java con una clase para cada tipo de mensaje, así como clases de constructor especiales para crear instancias de clases de mensajes.” de Documentacion) 

Se podría decir que un archivo .proto posee mayor fidelidad de los parámetros de la API que una documentación en texto humano, ya que la segunda puede ser confusa, erronea o desactualizada sin ninguna consecuencia inmediata.

Ejemplo de archivo proto, donde se admiran los servicios disponibles y como estan compuestos sus argumentos y valores de retorno:

```proto
// The greeting service definition.
service Emailer {
  // Sends a greeting
  rpc SendEmail (EmailRequest) returns (EmailReply) {}
}

// The request message containing the user's name.
message EmailRequest {
  string title = 1;
  string body = 2;
}

// The response message containing the greetings
message EmailReply {
  bool success = 1;
  string message = 2;
}
```