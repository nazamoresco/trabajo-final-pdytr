# Construcción del ejemplo base

El ejercicio base se desarrolló en la carpeta `base`.

Se utilizó [la guía de GRPC por Google](https://grpc.io/docs/languages/ruby/quickstart/) para la construcción del ejemplo.

Para el ejemplo base se eligió hacer un cliente y servidor de email.

En el archivo `.proto` se definió una interacción básica donde el cliente envía un email al servidor y este responde con el estado de éxito de la operación.

En todos los lenguajes que ofrece gRPC estos `.protos` se definen de la misma manera.

```proto
syntax = "proto3";

option java_multiple_files = true;
option java_package = "io.grpc.examples.email";
option java_outer_classname = "EmailProto";
option objc_class_prefix = "E";

package email;

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

Luego se definió el cliente, por ahora simplemente envía un email al puerto 50051, default en GRPC, y espera una respuesta.

```ruby
hostname = 'localhost:50051'
stub = Email::Emailer::Stub.new(hostname, :this_channel_is_insecure)
email = Email::EmailRequest.new(title: "Greetings", body: "Greetings from WC champion Argentina.")
email_response = stub.send_email(email)

puts "The email was successful?: #{email_response.success}, message: #{email_response.message}"
```

Se definió también el servidor que por ahora simplemente recibe el email y envía una respuesta.
```ruby
class EmailServer < Email::Emailer::Service
  def send_email(email_req, _unused_call)
    Email::EmailReply.new(success: true, message: "Your email was store successfully")
  end
end

server = GRPC::RpcServer.new
server.add_http2_port('0.0.0.0:50051', :this_port_is_insecure)
server.handle(EmailServer)
server.run_till_terminated_or_interrupted([1, 'int', 'SIGTERM'])
```

Se construyó el siguiente Dockerfile para el cliente. A notar:
* Parte de un imagen Docker para ruby.
* Crea la carpeta `/client` como directorio de trabajo.
* Se instala la gema gRPC y otras herramientas relacionadas.
* Se copia el código al cliente.
* Se genera el código Ruby correspondiente al `.proto`.
* Se ejecuta como comando final el cliente.
```dockerfile
FROM ruby:3.0.0

RUN mkdir /client
WORKDIR /client

RUN gem install grpc

RUN chmod -R o-w /usr/local/bundle
RUN apt update
RUN apt install ruby-grpc-tools -y

COPY . /client

RUN grpc_tools_ruby_protoc /client/protos/email.proto -I /client/protos --grpc_out=lib --ruby_out=lib

CMD ["ruby", "./emailer_client.rb"]
```

Se construyó el siguiente Dockerfile para el servidor. A notar:
* Parte de un imagen Docker para ruby.
* Crea la carpeta `/server` como directorio de trabajo.
* Se instala la gema gRPC y otras herramientas relacionadas.
* Se instala la gema byebug para debuggear.
* Se copia el código al directorio de trabajo.
* Se genera el código Ruby correspondiente al `.proto`.
* Se expone el puerto 50051, donde escucha el servidor.
* Se ejecuta como comando final el servidor.
```ruby
FROM ruby:3.0.0

RUN mkdir /server
WORKDIR /server

RUN gem install grpc
RUN gem install grpc-tools
RUN gem install byebug

RUN chmod -R o-w /usr/local/bundle
RUN apt update
RUN apt install ruby-grpc-tools -y

COPY . /server

RUN grpc_tools_ruby_protoc ./protos/email.proto -I ./protos --grpc_out=lib --ruby_out=lib

EXPOSE 50051

CMD ["ruby", "./emailer_server.rb"]
```

Finalmente, se definió un docker-compose que integra estos dos Dockerfiles:
```yml
version: "3"
services:
  server:
    build:
      context: .
      dockerfile: Server
    container_name: base_server
    ports:
      - 50051:50051
  client:
    build:
      context: .
      dockerfile: Client
    container_name: base_client
    network_mode: host
    depends_on: 
      - server
```

Ahora con el comando `docker-compose up` es posible correr este ejemplo.

```sh
$ docker-compose up
Recreating base_server ... done
Recreating base_client ... done
Attaching to base_server, base_client
client_1  | The email was successful?: true, message: Your email was store successfully
base_client exited with code 0
```

[Siguiente](ej1_a.md)

[Volver](../../README.md)

