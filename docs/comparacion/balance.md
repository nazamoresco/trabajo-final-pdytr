# Balance final

En esta sección se compara REST y gRPC desde 4 puntos de vistas (transparencia, familaridad, documentación y performance).

## Familiaridad

Indiscutiblemente, en la actualidad los desarrolladores web están familiarizados con REST, las universidades enseñan desarrollo web en REST y en el ambito laboral se utiliza REST.

Por ejemplo, si un desarrollador web observa los siguientes snippets de codigo, problablemente entienda el REST más rápido que el gRPC:

```ruby
# gRPC
require 'grpc'
require 'football_services_pb'

stub = Football::Football::Stub.new('localhost:50051', :this_channel_is_insecure)

response = stub.list_matches Football::ListMatchesRequest.new
my_match = response.matches.first

call = stub.listen_match(Football::ListenMatchRequest.new(match: my_match))

call.each do |event_res|
  puts event_res.event
end
```

```ruby
# REST
require "http"

response = HTTP.get("http://localhost:4567/list-matches").parse
match = response["matches"][0]

response = HTTP.get("http://localhost:4567/listen-match/#{match}")
response.body.each { |x| puts x }
```

Las explicaciones a la afirmación anterior se haya en la familiaridad de los desarrollares web con el protocolo REST, que facilita la identificación de la intencionalidad detrás del código:
  * Los desarrolladores web estan familarizados con las pocas acciones que REST define (GET, PUT, POST, DELETE, etc).
  * Los desarrolladores web estan familarizados con el protocolo JSON (utilizado por REST) y sus peculiaridades. 
  * Los desarrolladores web estan familarizados con los estándares de REST, por ejemplo que para actualizar un recurso se debe hacer una petición HTTP a `PUT recurso/id`.

Por otro lado, si se observa el cliente de gRPC se introducen nuevas clases como `Football::Football::Stub`, `Football::ListenMatchesRequest` y `Football::ListenMatchRequest`, que Íaunque el desarrollador puede intuir levemente no le son conocidas y le introducen incertidumbre.

Esta falta de familariedad de los desarrolladores web con REST puede implicar que encontrar desarrolladores para un proyecto en gRPC puede ser un desafio.

## Transparencia

REST no brinda un mecanismo para consultar los parametros y valores de retorno de un enpoint. Si un desarrollador quiere saber que parametros recibe un endpoint en REST debe tener acceso al código, de no ser así debe acceder a una documentación (potencialmente desactualizada o errónea), de no ser así no le quedara de otra que hacer ingeniería inversa al endpoint.

gRPC resuelve este problema con `protocol buffers`, en todo momento los desarrolladores de gRPC saben cuales son los parámetros de entradas y cuales los valores de retorno.

Para ahondar más en este punto revisar [el ejercicio 3](../tp3/ej3.md).

## Documentación

La documentación de Sinatra es clara y de extensa comunidad, este no es el caso con de gRPC en Ruby.

La guia de Google de gRPC en Ruby es difícil de seguir y se requiere de un conocimiento avanzado en temas de Ruby como `Enumerators`. Se encontró tutoriales muy bien indexados en Google que directamente estaban mal. En este sentido REST es mucho más amigable para nuevos desarrolladores que gRPC, al menos en Ruby.

## Performance

Se llevó a cabo mediciones de 100 iteraciones en las carpetas `grpc_performance` y `rest_performance`:

| gRPC | Tiempo total | Promedio | Desviación estándar |
| ---------- | -- | -- | ---|
| Listar partidos | 44.128 ms | 0.441ms | 0.255ms
| Comentarista con 100 comentarios   | 334.55 ms     | 3.346 ms | 0.601 ms |


| REST | Tiempo total | Promedio | Desviación estándar |
| ---------- | -- | -- | ---|
| Listar partidos | 86.303 ms | 0.863ms | 0.298ms
| Comentarista con 100 comentarios   | 8015.178 ms     | 80.152 ms  | 7.958 ms |

Como se aprecia, gPRC es más rápido y más estable en sus tiempos de comunicación, algunas explicaciones:
* GRPC utiliza Protocol Buffers que es más rápido que JSON o YML, utilizados por REST.
* GRPC hace uso del protocolo HTTP/2 que es más eficiente que el protocolo HTTP/1.1 utilizado por REST.

## Conclusión

Ninguna de las dos herramientas es objetivamente una mejor opción sino que dependerá más del proyecto. gRPC es una buena opcion para proyectos donde la velocidad y la transparencia son importante, por otro lado, REST es una buena opcion para proyectos donde se necesite de muchos desarrolladores o se deban implementar rapidamente.Íß

[Volver](intro.md)