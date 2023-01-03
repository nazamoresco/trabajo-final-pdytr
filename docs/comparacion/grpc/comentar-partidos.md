
### Comentar partidos

Para comentar partidos necesitaremos definir un endpoint de client-streaming. El cliente enviara el partido y los comentarios, del server no presisamos ninguna informacion.

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

El server realiza las siguientes tareas:
* Recibe los comentarios y los agrega al archivo correspondiente.
* Le envia al modulo `Referee` el comentario para que lo analice, y agrega una potencial sanción al archivo.

```ruby
class Server < Football::Football::Service
  def comment_match(comment_reqs)
    referee = Referee.new

    comment_reqs.each_remote_read do |comment_req|
      file = File.open("matches/#{comment_req.match}", "a") 
      file << "#{comment_req.comment}\n" 

      santion = referee.observe(comment_req.comment)
      file << "#{santion}\n" unless santion.nil?
      
      file.close
    end

    Football::CommentMatchResponse.new
  end
end
```

El cliente define una clase para la logica del comentario, no es interesante si el enforque es en gRPC, pero devuelve un comentario en el metodo `comment`.
```ruby
class Commentator
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

Se define otra clase que consuma a `Commentator` y envie las peticiones al server.
```ruby
class ComentaristaStreamer
  MAX_BYTES = 4_194_308
  
  def initialize(match)
    @match = match
    @commentator = Commentator.new(
      local: match.split("-")[0],
      visitor: match.split("-")[1]
    )
  end

  def each
    return enum_for(:each) unless block_given?

    100.times do
      yield Football::CommentMatchRequest.new(
        match: @match,
        comment: @commentator.comment
      )
    end
  end
end
```

Y en el cliente se utiliza esta clase, ademas que se listan los matches anteriormente para identificar el partido:
```ruby
stub = Football::Football::Stub.new('localhost:50051', :this_channel_is_insecure)

response = stub.list_matches Football::ListMatchesRequest.new
my_match = response.matches.first

stub.comment_match(
  ComentaristaStreamer.new(my_match).each
)
```

El archivo se ve asi luego de ejecutar el commentator: 
```
El jugador de francia regatea a la derecha al delantero de argentina.
El jugador de argentina pasa a la izquierda al delantero de argentina.
El jugador de argentina regatea a la derecha al delantero de francia.
El jugador de francia barre a la izquierda al arco de argentina.
El jugador de argentina pasa a la izquierda al defensor de argentina.
```

Se define un dockerfile Commentator, estandard.
```Dockerfile
FROM ruby:3.0.0

RUN mkdir /client
WORKDIR /client

RUN gem install grpc

RUN chmod -R o-w /usr/local/bundle
RUN apt update
RUN apt install ruby-grpc-tools -y 

COPY commentator /client/commentator
COPY matches /client/matches
COPY lib /client/lib
COPY protos /client/protos

RUN grpc_tools_ruby_protoc /client/protos/football.proto -I /client/protos --grpc_out=lib --ruby_out=lib

CMD ["ruby", "./commentator/commentator.rb"] 
```

Se agregar el `commentator` al `docker-compose`:
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
  commentator:
    build:
      context: .
      dockerfile: Commentator
    container_name: comparacion_grpc_comentarista
    network_mode: host
    depends_on: 
      - server
  listener:
    build:
      context: .
      dockerfile: listener
    container_name: comparacion_grpc_oyente
    network_mode: host
    depends_on: 
      - commentator
```

A continuación [escuchar partidos](escuchar-partidos.md).