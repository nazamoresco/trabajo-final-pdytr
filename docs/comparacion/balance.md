## Balance final

Luego de utilizadas ambas herramientas, se analizaran distintos puntos en cada una de las tecnologias.

#### Familiridad

Los desarrolladores web a dia de hoy estan muy familiarizados con REST, en la universidad la mayorias de las materias web se realizan con REST, gran parte del mercado laboral utiliza REST.
Esto es en si un gran desafio a la hora de encontrar desarrolladores para que trabajen en el proyecto.
Es casi seguro que la mayoria de los desarrolladores, entenderan el cliente de REST mucho mas rapido que el cliente gRPC.

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

Y esto tiene todo que ver con la familiriadad, REST define pocas acciones GET, PUT, POST, DELETE, etc, por esta razon es facil identificar cual es la intencionlidad detras de este codigo.
Tambien estan familiarizados con el protocolo jSon y sus peculirdades. Conocen de estandares, como actualidar a un recurso con `PUT recurso/id`, etc.

Si se observa el cliente de gRPC se introducen varias clases como `Football::Football::Stub`, `Football::ListenMatchesRequest` y `Football::ListenMatchRequest`, que aunque el desarrollador puede intuir que hacen no tiene una certeza sin revisar. `listen_match` parece devolver un stream pero no hay certeza a menos que se consulte la carpeta `/lib` o el `.proto`.


#### Transparencia

Si bien REST es mucho mas familiar, esto en gran parte se debe a sus convenciones, donde no existen estas REST empieza a flaquear.
Por dar un ejemplo, los parametros y los valores de retorno.

Si el desarrollador quisiera saber que parametros recive un endpoint en REST deberia tener acceso al codigo, de no ser asi debera acceder a una documentacion (potencialmente desactualizada o erronea), de no ser asi no le quedara de otra que hacer ingeniera inversa al endpoint.

gRPC resuelve este problema con `proto`, en todo momento los desarrolladores de gRPC saben cuales son los parametros de entradas y cuales los valores de retorno. 

Para ahondar mas en este punto revisar [el ejercicio 3](../tp3/ej3.md).

#### Documentacion

La documentacion de Sinatra es clara, la comunidad extensa, no se puede decir lo mismo de gRPC en Ruby, la guia de Google es dificil de seguir y se require de un conocimiento avanzado en temas de Ruby como `Enumerators`, se encontró tutoriales muy bien indexados en google que directamente estaban mal. En este sentido REST es mucho mas amigable para nuevos desarrolladores que gRPC.


#### Performance

Existen varias razones por las que gRPC es mas performante que REST:
* Uso de protocol buffers vs json o yml.
* Uso del protocolo HTTP/2 vs HTTP/1.1