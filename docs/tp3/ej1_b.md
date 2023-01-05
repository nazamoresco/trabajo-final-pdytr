# Ejercicio 1B
```
1. Utilizando como base el programa ejemplo1 de gRPC:
Mostrar experimentos donde se produzcan errores de conectividad del lado del
cliente y del lado del servidor.

b) Configure un DEADLINE y cambie el código (agregando la función sleep())
para que arroje la excepción correspondiente.
```

Se configuró un deadline de 2 segundos y se modificó el código del servidor con un `sleep(3)` para asegurar que se exceda el deadline definido.

Timeout en el cliente:
```ruby
hostname = 'localhost:50051'
stub = Email::Emailer::Stub.new(hostname, :this_channel_is_insecure, timeout: 2) # Aca
email = Email::EmailRequest.new(title: "Greetings", body: "Greetings from WC champion Argentina.")
email_response = stub.send_email(email)

puts "The email was successful?: #{email_response.success}, message: #{email_response.message}"
```

Sleep en el servidor:
```ruby
class EmailServer < Email::Emailer::Service
  def send_email(email_req, _unused_call)
    sleep(3) # Aca

    Email::EmailReply.new(success: true, message: "Your email was store successfully")
  end
end
```

El cliente responde con este error:
```
4:Deadline Exceeded. debug_error_string:{UNKNOWN:Deadline Exceeded {created_time:"2022-12-24T17:00:33.421745984+00:00", grpc_status:4}} (GRPC::DeadlineExceeded)
```

[Siguiente](ej1_c.md)

[Volver](../../README.md)