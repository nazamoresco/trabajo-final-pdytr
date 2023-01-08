

# Listar partidos

Se comenzó implementando la comunicación unaria. No es necesario que el cliente envie ningun dato en especial, pero el servidor devuelve una lista de strings.

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

Finalmente se definió el `docker-compose`, tambien bastante standard.
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


A continuación [comentar partidos](comentar-partidos.md).