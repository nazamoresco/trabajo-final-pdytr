```
1. Utilizando como base el programa ejemplo1 de gRPC:
Mostrar experimentos donde se produzcan errores de conectividad del lado del
cliente y del lado del servidor.

a) Si es necesario realice cambios mínimos para, por ejemplo, incluir exit(), de
forma tal que no se reciban comunicaciones o no haya receptor para las
comunicaciones.
```

A countinuacion se listaran los distintos errores de conectividad encontrados:

## Error de conectividad #1: El servidor no está corriendo en esa dirección

Cuando se corre el cliente sin un server disponible se obtiene el siguiente error:
```
> ERROR: 14:failed to connect to all addresses; last error: UNKNOWN: Failed to connect to remote host: Connection refused. debug_error_string:{UNKNOWN:Failed to pick subchannel {created_time:"2022-10-01T17:13:06.754513321-03:00", children:[UNKNOWN:failed to connect to all addresses; last error: UNKNOWN: Failed to connect to remote host: Connection refused {grpc_status:14, created_time:"2022-10-01T17:13:06.754510837-03:00"}]}}
```

## Error de conectividad #2: El servidor hace exit antes de responder:

Para este error se mofiica el servidor (`emailer_server`) para recibir la peticion del cliente, pero terminar antes de enviarle una respuesta. 
```ruby
class EmailServer < Email::Emailer::Service
  def send_email(email_req, _unused_call)
    # Exit before answering.
    exit 

    Email::EmailReply.new(success: true, message: "Your email was store successfully")
  end
end
```

Se notifica el siguiente error en el cliente:
```
/usr/local/bundle/gems/grpc-1.50.0-x86_64-linux/src/ruby/lib/grpc/generic/active_call.rb:29:in `check_status': 1:CANCELLED. debug_error_string:{UNKNOWN:Error received from peer ipv4:127.0.0.1:50051 {created_time:"2022-12-22T00:05:11.851600505+00:00", grpc_status:1, grpc_message:"CANCELLED"}} (GRPC::Cancelled)
```

El servidor fall con el siguiente error:
```
 E1222 00:05:11.852187204       1 completion_queue.cc:284]    assertion failed: completed_head.next == reinterpret_cast<uintptr_t>(&completed_head)
``` 

## Error de conectividad #3: El servidor sufre una exepcion

En este caso, el servidor no termina sino que falla por un error de codigo.
```ruby
class EmailServer < Email::Emailer::Service
  def send_email(email_req, _unused_call)
    # Exception before answering.
    1/0 

    Email::EmailReply.new(success: true, message: "Your email was store successfully")
  end
end
```

Falla en el cliente con el siguiente error:
```
 /usr/local/bundle/gems/grpc-1.50.0-x86_64-linux/src/ruby/lib/grpc/generic/active_call.rb:29:in `check_status': 2:ZeroDivisionError: divided by 0. debug_error_string:{UNKNOWN:Error received from peer ipv4:127.0.0.1:50051 {grpc_message:"ZeroDivisionError: divided by 0", grpc_status:2, created_time:"2022-12-22T00:13:55.85660856+00:00"}} (GRPC::Unknown)
 ```

Es interesante notar que en el servidor no existen logs del incidente.