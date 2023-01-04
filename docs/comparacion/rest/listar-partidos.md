### Listar partidos

Listar partidos en un GET Request común y corriente.

El docker-compose se copió del de gRPC, se cambió el puerto expuesto ya que Sinatra corre en el puerto 4567 por default:

```yml
# file comparacion/rest/docker-compose.yml
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

El Dockerfile para el cliente tambien esta basado en el de gRPC, cambiando unicamente las gemas requeridas:

```Dockerfile
# file comparacion/rest/Listener
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
# file comparacion/rest/Server
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
Observar como se define la ruta que debera ser consultada con una petición HTTP/1 GET.

```ruby
# file comparacion/rest/server/server.rb
require 'sinatra'

get '/list-matches' do
  {
    matches: Dir["./matches/*"].map { |match| match.gsub(/\.\/matches\//i, "") }.sort
  }.to_json
end
```

El cliente realiza esta consulta con ayuda de la gema `http`:
```ruby
# file comparacion/rest/listener/listener.rb
require "http"

response = HTTP.get("http://localhost:4567/list-matches").parse
match = response["matches"][0]
```

A continuación [comentar partidos](comentar-partidos.md).