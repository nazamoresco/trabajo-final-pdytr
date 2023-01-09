# Listar partidos

Listar partidos se puede resolver con un GET Request común y corriente.

El docker-compose se copió del de gRPC, se cambió el puerto expuesto ya que Sinatra corre en el puerto 4567 por default:

```yml
version: "3"
services:
  server:
    build:
      context: .
      dockerfile: Server
    container_name: comparacion_rest_server
    ports:
      - 4567:4567
  commentator:
    build:
      context: .
      dockerfile: Commentator
    container_name: comparacion_rest_comentarista
    network_mode: host
    depends_on:
      - server
  listener:
    build:
      context: .
      dockerfile: Listener
    container_name: comparacion_rest_oyente
    network_mode: host
    depends_on:
      - commentator
```

El Dockerfile para el cliente también está basado en el de gRPC, cambiando únicamente las gemas requeridas:

```Dockerfile
FROM ruby:3.0.0

RUN mkdir /client
WORKDIR /client

RUN gem install http
RUN gem install json

COPY listener /client/listener
COPY matches /client/matches

CMD ["ruby", "./listener/listener.rb"] 
```

IDEM para el servidor:
```Dockerfile
FROM ruby:3.0.0

RUN mkdir /server
WORKDIR /server

RUN gem install sinatra
RUN gem install puma

COPY server /server/server
COPY matches /server/matches

EXPOSE 4567

CMD ["ruby", "./server/server.rb"]
```

El servidor mantiene la lógica para obtener los partidos.
Observar cómo se define la ruta que deberá ser consultada con una petición HTTP GET.

```ruby
get "/list-matches", provides: "application/json" do
  {
    matches: Dir["./matches/*"].map { |match| match.gsub(/\.\/matches\//i, "") }.sort
  }.to_json
end
```

El cliente realiza esta consulta con ayuda de la gema `http`:
```ruby
require "http"

response = HTTP.get("http://localhost:4567/list-matches").parse
match = response["matches"][0]
```

[Siguiente](comentar-partidos.md)

[Volver](../intro.md)

