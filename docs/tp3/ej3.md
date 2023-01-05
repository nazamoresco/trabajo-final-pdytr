# Ejercicio 3
```
3) Analizar la transparencia de gRPC en cuanto al manejo de parámetros de los procedimientos remotos. Considerar lo que sucede en el caso de los valores de retorno. Puede aprovechar el ejemplo provisto.
```

La transparencia del manejo de parámetros en gRPC radica en el archivo .proto, ya que gracias a este tanto el cliente como el servidor se conocen los servicios definidos con sus respectivos parametros y valores de retorno.

Para contrastar, en un API REST tradicional el cliente debe acceder a una documentación para conocer los distintos parámetros, en cambio en gRPC se tiene el archivo .proto, escrito en un DSL que genera código necesario para el funcionamiento de la API. (Bajo la carpeta lib/ se encuentran las clases en Ruby generadas con gRPC a partir del `.proto`)

Se podría decir que un archivo .proto posee mayor fidelidad de los parámetros de la API que una documentación en texto humano, ya que la segunda puede ser confusa, erronea o desactualizada sin ninguna consecuencia inmediata.

Ejemplo de archivo proto, donde se admiran los servicios disponibles y como estan compuestos sus argumentos y valores de retorno:

```proto
service Emailer {
  rpc SendEmail (EmailRequest) returns (EmailReply) {}
}

message EmailRequest {
  string title = 1;
  string body = 2;
}

message EmailReply {
  bool success = 1;
  string message = 2;
}
```

[Siguiente](ej4_a.md)

[Volver](../../README.md)