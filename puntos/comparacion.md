Primero se plantea una idea para un proyecto, luego se implementa en ambas tecnicas (REST y gRPC) en Ruby, y finalmente se compararan en distintos puntos.

## La idea

Es el año 2026, FIFA ha encomendado a un grupo de desarrolladores en Ruby la implementacion de un sistema de arbitraje super automatizado.

El sistema tendrá dos modulos princpales el Commentator y el Arbitro.

El Commentator es un cliente que se encarga de enviar al server todos los eventos en alta presicion que registra mediante las camaras de los telefonos de la tribuna y las camaras de los distintos medios periodisticos.

El Arbitro es un modulo que recide en el server y debe escuchar a los comentarios al Commentator, en caso de detectar una falta lo debe guardar en el server la sanción acorde, donde podra ser escuchada por los clientes.

Finalmente tambien existen los Oyentes, estos son usuarios humanos que escucharan los matches relatados por el Commentator y arbitrados por el Arbitro.

Lamentablemente el grupo de desarrolladores no ha logrado llegar a un consenso para el mejor framework a utilizar, REST o gRPC. FIFA decidió la creacion de dos MVPs, uno con cada tecnologia, con la esperanza de que se logre consensuar sobre la mejor tecnologia para llevar a cabo el proyecto. 

## La Implementacion

Se requiren las siguientes interacciones con el server:

1. Listar los matches
   * Pueden existir distintos matches simultaneos, los clientes debe ser capaces de listarlos.
   * Comunicacion unaria, en el futuro puede ser un server streaming.
   * El cliente pide listar los matches.
   * El server devuelve un string que contiene los nombres de los matches separados por punto y coma.
2. Escuchar los matches
   * El cliente envia un string que identifica al partido que quiere escuchar.
   * El server streamea los arbitrajes y comentarios que suceden, y tambien debe notificar de la finalizacion de un partido.
   * En general, los Oyentes usaran este endpoint.
   * Comunicacion server-streaming.
3. Comentar los matches
   * El cliente envia logs de los eventos del partido al server, esto es un string simple.
   * El server registra y distribuye a los demas oyentes.
   * En general los Comentaristas usaran este endpoint.
   * Comunicacion client-streaming. 


## La implementancion de gRPC

Se ha modificó la estructura de los archivos en el cógido respecto a los ejercicios anteriores. Se intenta plantear un ejemplo mas de produccion donde el cliente no deberia tener acceso a los archivos del server, como ocurre en previos ejercicios.

Se decidío la siguiente estructura: 
```
|_ lib/ ~ archivos generados por grpc
|_ listener/ ~ codigo del listener
|_ matches/ ~ contiene los archivos de los matches
|_ protos/ ~ contine los protos
|_ server/ ~ contiene el codigo del server
```

### Listar matches

Se comenzó implementando la comunicación unaria. No es necesario que el cliente envie ningun dato en especial, pero el server devolvera una lista de strings.

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

El server revisa la carpeta de matches, formatea los nombre de los archivos, los ordena y los envia al cliente.

```ruby
class Server < Football::Football::Service
  def list_matches(email_req, _unused_call)
    Football::ListMatchesResponse.new(
      matches: Dir["./matches/*"].map { |match| match.gsub(/\.\/matches\//i, "") }.sort
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

COPY server /server/server
COPY matches /server/matches
COPY lib /server/lib
COPY protos /server/protos

RUN grpc_tools_ruby_protoc ./protos/football.proto -I ./protos --grpc_out=lib --ruby_out=lib

EXPOSE 50051

CMD ["ruby", "./server/server.rb"] 
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

COPY listener /client/listener
COPY matches /client/matches
COPY lib /client/lib
COPY protos /client/protos

RUN grpc_tools_ruby_protoc /client/protos/football.proto -I /client/protos --grpc_out=lib --ruby_out=lib

CMD ["ruby", "./listener/listener.rb"] 
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
  listener:
    build:
      context: .
      dockerfile: listener
    container_name: comparacion_grpc_oyente
    network_mode: host
    depends_on: 
      - server
```

### Comentar matches

Para comentar matches necesitaremos definir un endpoint de client-streaming. El cliente enviara el partido y los comentarios, del server no presisamos ninguna informacion.

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

El referee

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

## Escuchar matches

Para este endpoint, se necesitó de un endpoint con server streaming.
Como se observa en la respuesta se incluirá si el partido ha finalizado.
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
  bool match_over = 2;
}
```

El el listener se realizó una pequeña modificacion luego de listar los matches, selecciona el primero y hace un request para escucharlo.
```ruby
response = stub.list_matches Football::ListMatchesRequest.new
my_match = response.matches.first

call = stub.listen_match(Football::ListenMatchRequest.new(match: my_match))

call.each do |event_res|
  puts event_res.event
  break if event_res.match_over
end
```

En el server, se *stremea* desde la clase `MatchListener`
```ruby
class Server < Football::Football::Service
  def listen_match(listen_req, _unused_call)
    MatchListener.new(listen_req.match).each
  end
end
```

La clase `MatchListener` accede al archivo correspondiente al partido y stremea los eventos en él al cliente.
El enumerador que se contruyó es distintos a los de ejercicio anteriores, ya que no itera por datos, escucha a un archivo, por esta razon se explica en mayor detalle el metodo `each`.
```ruby
class MatchListener
  def initialize(match)
    @match = match
  end

  def each
    return enum_for(:each) unless block_given?
    
    real_time_match_listener = Enumerator.new do
      lines = File.open("matches/#{@match}", "r").each_line
      already_read_bytes = 0

      loop do
        next_line = nil
        waits = 10
        
        while next_line.nil?
          begin
            next_line = lines.next
            already_read_bytes += next_line.length
          rescue StopIteration
            sleep(1) # Wait a second for new lines
            file = File.open("matches/#{@match}", "r")
            file.seek(already_read_bytes)
            lines = file.each_line
            waits -= 1

            raise if waits == 0
          end
        end
        
        yield Football::ListenMatchResponse.new(
          event: next_line,
          match_over: false
        )
      rescue StopIteration
        yield Football::ListenMatchResponse.new(
          event: "GAME OVER",
          match_over: true
        )
      end
    end

    real_time_match_listener.each { |result| yield result }
  end
end
```

Normalmente un enumerador se ve asi en Ruby: 
```ruby
100.times
datos.each
file.each_line
```

Estas formas tienen en comun que se evalua los datos a recorrer antes de crear el enumerador.
El rango numerico debe ser evaluado, los datos contruidos y el archivo abierto.
Pero en esto problema se necesita acceder a nuevos datos que puede aparecer una vez evaluado nuestro enumerador.
Por esto se utilizó este metodo: 

```ruby
  real_time_match_listener = Enumerator.new do
    # inicializacion

    loop do
      # siguiente cosa a devolver
    end
  end
```

Lo que el lector debe enterder es que es una especie de enumerador "infinito", la lógica para cada nuevo elemento se encuentra en el bloque `loop` , cuenta con un estado definido en `inicializacion` y es posible finalizar la iteracion levantando una excepcion en `loop` (`StopIteration`).

En la inicializacion se abre el archivo por primera vez y se crea una variable para hacer un seguimientos de los bytes leidos.

```ruby
  real_time_match_listener = Enumerator.new do
    lines = File.open("matches/#{@match}", "r").each_line
    already_read_bytes = 0

    loop do
      # siguiente cosa a devolver
    end
  end
```

Finalmente se generó la logica para construir el siguiente elemento.
Puntos a observar:
* Si existen aun lineas para leer del archivos abierto, se lee y actualiza los bytes leidos.
* Si no existen lineas para leer:
  * Se espera 1 segundo.
  * Se abre nuevamente el archivo para acceder a nuevo contenido, pero se mueve el puntero del archivo a la ultima posicion leida.
  * Se realizara 10 veces esta logica, en caso de no encontrar nuevo contenido, se considerá finalizado el partido.

```ruby
  real_time_match_listener = Enumerator.new do
    lines = File.open("matches/#{@match}", "r").each_line
    already_read_bytes = 0

    loop do
      next_line = nil
      waits = 10
      
      while next_line.nil?
        begin
          next_line = lines.next
          already_read_bytes += next_line.length
        rescue StopIteration
          sleep(1) # Wait a second for new lines
          file = File.open("matches/#{@match}", "r")
          file.seek(already_read_bytes)
          lines = file.each_line
          waits -= 1

          raise if waits == 0
        end
      end
      
      yield Football::ListenMatchResponse.new(
        event: next_line
      )
    end
  end
```