
# Comentar partidos

Para comentar partidos se necesitó definir un endpoint de client-streaming. El cliente envía el partido y los comentarios, del servidor no precisamos ninguna información.

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

El servidor realiza las siguientes tareas:
* Recibe los comentarios y los agrega al archivo correspondiente.
* Le envía al módulo `Referee` el comentario para que lo analice y devuelvas una potencial sanción al archivo.

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

El cliente define una clase para la lógica del comentario, no es interesante si el enfoque es en gRPC, pero devuelve un comentario en el método `comment`.
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

Se define otra clase que consuma a `Commentator` y envíe las peticiones al servidor.
```ruby
class CommentsStreamer
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

Y en el cliente se utiliza esta clase, además que se listan los partidos anteriormente consultados para identificar el partido:
```ruby
stub = Football::Football::Stub.new('localhost:50051', :this_channel_is_insecure)

response = stub.list_matches Football::ListMatchesRequest.new
my_match = response.matches.first

stub.comment_match(
  CommentsStreamer.new(my_match).each
)
```

El archivo se ve así luego de ejecutar el commentator:
```
El jugador de Francia regatea a la derecha al delantero de Argentina.
El jugador de argentina pasa a la izquierda al delantero de argentina.
El jugador de Argentina regatea a la derecha al delantero de Francia.
El jugador de Francia barre a la izquierda al arco de Argentina.
El jugador de Argentina pasa a la izquierda al defensor de Argentina.
```

Se agregó el `commentator` al `docker-compose`:
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

[Siguiente](escuchar-partidos.md)

[Volver](../intro.md)


