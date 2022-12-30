Primero se plantea una idea para un proyecto, luego se implementa en ambas tecnicas (REST y gRPC) en Ruby, y finalmente se compararan en distintos puntos.

## La idea

Es el año 2026, FIFA ha encomendado a un grupo de desarrolladores en Ruby la implementacion de un sistema de arbitraje super automatizado.

El sistema tendrá dos modulos princpales el Comentarista y el Arbitro.

El Comentarista es un cliente que se encarga de enviar al servidor todos los eventos en alta presicion que registra mediante las camaras de los telefonos de la tribuna y las camaras de los distintos medios periodisticos.

El Arbitro es un cliente que escucha atentanmente al Comentarista, en caso de detectar una falta le enviara al servidor la sanción acorde y la derivara el mismo a un sistema externo (no será necesario implementarlo para el MVP).

Finalmente tambien existen los Oyentes, estos son usuarios humanos que escucharan los partidos relatados por el Comentarista y arbitrados por el Arbitro.

Lamentablemente el grupo de desarrolladores no ha logrado llegar a un consenso para el mejor framework a utilizar, REST o gRPC. FIFA decidió la creacion de dos MVPs, uno con cada tecnologia, con la esperanza de que se logre consensuar sobre la mejor tecnologia para llevar a cabo el proyecto. 

## La Implementacion

Se requiren las siguientes interacciones con el servidor:

1. Listar los partidos
   * Pueden existir distintos partidos simultaneos, los clientes debe ser capaces de listarlos.
   * Comunicacion unaria, en el futuro puede ser un server streaming.
   * El cliente pide listar los partidos.
   * El servidor devuelve un string que contiene los nombres de los partidos separados por punto y coma.
2. Escuchar los partidos
   * El cliente envia un string que identifica al partido que quiere escuchar.
   * El servidor streamea los arbitrajes y comentarios que suceden.
   * En general, los Oyentes usaran este endpoint.
   * Comunicacion server-streaming.
3. Comentar los partidos
   * El cliente envia logs de los eventos del partido al servidor, esto es un string simple.
   * El servidor registra y distribuye a los demas oyentes.
   * En general los Comentaristas usaran este endpoint.
   * Comunicacion client-streaming. 
4. Arbitrar los partidos
   * El cliente envia al servidor el partido que quiere arbitrar y las potenciales sanciones.
   * El servidor envia al cliente los comentarios del Comentarista.


## La implementancion de gRPC

Se ha modificó la estructura de los archivos en el cógido respecto a los ejercicios anteriores. Se intenta plantear un ejemplo mas de produccion donde el cliente no deberia tener acceso a los archivos del servidor, como ocurre en previos ejercicios.

Se decidío la siguiente estructura: 
```
|_ lib/ ~ archivos generados por grpc
|_ oyente/ ~ codigo del oyente
|_ partidos/ ~ contiene los archivos de los partidos
|_ protos/ ~ contine los protos
|_ servidor/ ~ contiene el codigo del servidor
```

### Listar partidos

Se comenzó implementando la comunicación unaria. No es necesario que el cliente envie ningun dato en especial, pero el servidor devolvera una lista de strings.

```proto
package football;

service Football {
  rpc ListMatches(ListMatchesRequest) returns (ListMatchesResponse) {}
}

message ListMatchesRequest {}

message ListMatchesResponse {
  repeated string matches = 2;
}
```

El servidor revisa la carpeta de partidos, formatea los nombre de los archivos, los ordena y los envia al cliente.

```ruby
class Server < Football::Football::Service
  def list_matches(email_req, _unused_call)
    Football::ListMatchesResponse.new(
      matches: Dir["./partidos/*"].map { |match| match.gsub(/\.\/partidos\//i, "") }.sort
    )
  end
end
``` 

El `Dockerfile` es similar a anteriores, aunque capaz es interesante observar que la copia de los archivos es mas selectiva.
```Dockerfile
FROM ruby:3.0.0

RUN mkdir /server
WORKDIR /server

RUN gem install grpc
RUN gem install grpc-tools
RUN gem install byebug

RUN chmod -R o-w /usr/local/bundle
RUN apt update
RUN apt install ruby-grpc-tools -y 

COPY servidor /server/servidor
COPY partidos /server/partidos
COPY lib /server/lib
COPY protos /server/protos

RUN grpc_tools_ruby_protoc ./protos/football.proto -I ./protos --grpc_out=lib --ruby_out=lib

EXPOSE 50051

CMD ["ruby", "./servidor/server.rb"] 
```

Luego se debe crear el cliente para los Oyentes.
El cliente es similar a clientes anteriores.

```ruby
stub = Football::Football::Stub.new('localhost:50051', :this_channel_is_insecure)
response = stub.list_matches Football::ListMatchesRequest.new

puts response.matches
``` 

El Dockerfile tambien lo es.
```Dockerfile
FROM ruby:3.0.0

RUN mkdir /client
WORKDIR /client

RUN gem install grpc

RUN chmod -R o-w /usr/local/bundle
RUN apt update
RUN apt install ruby-grpc-tools -y 

COPY oyente /client/oyente
COPY partidos /client/partidos
COPY lib /client/lib
COPY protos /client/protos

RUN grpc_tools_ruby_protoc /client/protos/football.proto -I /client/protos --grpc_out=lib --ruby_out=lib

CMD ["ruby", "./oyente/oyente.rb"] 
``` 

Finalmente se definio el `docker-compose`, tambien bastante standard.
```yml
version: "3"
services:
  server:
    build:
      context: .
      dockerfile: Server
    container_name: comparacion_grpc_server
    ports:
      - 50051:50051
  oyente:
    build:
      context: .
      dockerfile: Oyente
    container_name: comparacion_grpc_oyente
    network_mode: host
    depends_on: 
      - server
```

### Comentar partidos

Para comentar partidos necesitaremos definir un endpoint de client-streaming. El cliente enviara el partido y los comentarios, del servidor no presisamos ninguna informacion.

```proto
service Football {
  rpc ListMatches(ListMatchesRequest) returns (ListMatchesResponse) {}
  rpc CommentMatch(stream CommentMatchRequest) returns (CommentMatchResponse) {}
}

// Comment match
message CommentMatchRequest {
  string match = 1;
  string comment = 2;
}

message CommentMatchResponse {}
```

El servidor recibe los comentarios, abre el archivo correspondiente y lo appendea. Una vez que no existan mas comentarios cierra el archivo y cierra la comunicacion.
```ruby
class Server < Football::Football::Service
  def comment_match(comment_reqs)
    file = nil
    comment_reqs.each_remote_read do |comment_req|
      file ||= File.open("partidos/#{comment_req.match}", "a") 
      file << "#{comment_req.comment}\n" 
    end
    
    file.close
    Football::CommentMatchResponse.new
  end
end
```

El cliente define una clase para la logica del comentario, no es interesante si el enforque es en gRPC, pero devuelve un comentario en el metodo `comment`.
```ruby
class Comentarista
  ACTIONS = ["barre", "regatea", "define", "pasa"]
  DIRECTIONS = ["izquierda", "derecha"]
  ACTED = ["arquero", "arco", "defensor", "delantero"]

  def initialize(local:,visitor:)
    @actors = [local, visitor]
  end

  def comment
    "El jugador de #{@actors.sample} #{ACTIONS.sample} a la #{DIRECTIONS.sample} al #{ACTED.sample} de #{@actors.sample}." 
  end
end
```

Se define otra clase que consuma a `Comentarista` y envie las peticiones al servidor.
```ruby
class ComentaristaStreamer
  MAX_BYTES = 4_194_308
  
  def initialize(match)
    @match = match
    @comentarista = Comentarista.new(
      local: match.split("-")[0],
      visitor: match.split("-")[1]
    )
  end

  def each
    return enum_for(:each) unless block_given?

    100.times do
      yield Football::CommentMatchRequest.new(
        match: @match,
        comment: @comentarista.comment
      )
    end
  end
end
```

Y en el cliente se utiliza esta clase, ademas que se listan los partidos anteriormente para identificar el partido:
```ruby
stub = Football::Football::Stub.new('localhost:50051', :this_channel_is_insecure)

response = stub.list_matches Football::ListMatchesRequest.new
my_match = response.matches.first

stub.comment_match(
  ComentaristaStreamer.new(my_match).each
)
```

El archivo se ve asi luego de ejecutar el comentarista: 
```
El jugador de francia regatea a la derecha al delantero de argentina.
El jugador de argentina pasa a la izquierda al delantero de argentina.
El jugador de argentina regatea a la derecha al delantero de francia.
El jugador de francia barre a la izquierda al arco de argentina.
El jugador de argentina pasa a la izquierda al defensor de argentina.
```

Se define un dockerfile Comentarista, estandard.
```Dockerfile
FROM ruby:3.0.0

RUN mkdir /client
WORKDIR /client

RUN gem install grpc

RUN chmod -R o-w /usr/local/bundle
RUN apt update
RUN apt install ruby-grpc-tools -y 

COPY comentarista /client/comentarista
COPY partidos /client/partidos
COPY lib /client/lib
COPY protos /client/protos

RUN grpc_tools_ruby_protoc /client/protos/football.proto -I /client/protos --grpc_out=lib --ruby_out=lib

CMD ["ruby", "./comentarista/comentarista.rb"] 
```

Se agregar el `comentarista` al `docker-compose`:
```yml
version: "3"
services:
  server:
    build:
      context: .
      dockerfile: Server
    container_name: comparacion_grpc_server
    ports:
      - 50051:50051
  comentarista:
    build:
      context: .
      dockerfile: Comentarista
    container_name: comparacion_grpc_comentarista
    network_mode: host
    depends_on: 
      - server
  oyente:
    build:
      context: .
      dockerfile: Oyente
    container_name: comparacion_grpc_oyente
    network_mode: host
    depends_on: 
      - comentarista
```

## Escuchar partidos

Para este endpoint, se necesitó de un endpoint con server streaming.

```proto
service Football {
  rpc ListMatches(ListMatchesRequest) returns (ListMatchesResponse) {}
  rpc CommentMatch(stream CommentMatchRequest) returns (CommentMatchResponse) {}
  rpc ListenMatch(ListenMatchRequest) returns (stream ListenMatchResponse) {}
}

// Listen Match
message ListenMatchRequest {
  string match = 1;
}

message ListenMatchResponse {
  string event = 1;
}
```

El el oyente se realizó una pequeña modificacion luego de listar los partidos, selecciona el primero y hace un request para escucharlo.
```ruby
response = stub.list_matches Football::ListMatchesRequest.new
my_match = response.matches.first

call = stub.listen_match(Football::ListenMatchRequest.new(match: my_match))

call.each do |event_res|
  puts event_res.event
end
```

En el servidor, se *stremea* desde la clase `MatchListener`
```ruby
class Server < Football::Football::Service
  def listen_match(listen_req, _unused_call)
    MatchListener.new(listen_req.match).each
  end
end
```

La clase `MatchListener` accede al archivo correspondiente al partido y stremea los eventos en él al cliente.
```ruby
class MatchListener
  def initialize(match)
    @match = match
  end

  def each
    return enum_for(:each) unless block_given?

    file = File.open("partidos/#{@match}", "r")
    file.each_line do |line|
      yield Football::ListenMatchResponse.new(
        event: line
      )
    end
  end
end
```

