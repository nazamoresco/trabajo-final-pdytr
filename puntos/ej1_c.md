```
1. Utilizando como base el programa ejemplo1 de gRPC:
Mostrar experimentos donde se produzcan errores de conectividad del lado del
cliente y del lado del servidor.

c) Reducir el deadline de las llamadas gRPC a un 10% menos del promedio
encontrado anteriormente. Mostrar y explicar el resultado para 10 llamadas.
```

Primero se encontró el promedio de respuesta.

Se agrego un codigo para simular trabajo:
```ruby
class EmailServer < Email::Emailer::Service
  def send_email(email_req, _unused_call)
    1_0000_0000.times { "Checking other emails" }

    Email::EmailReply.new(success: true, message: "Your email was store successfully")
  end
end
```

Luego se hizo 100 llamadas y se calculó el promedio.
```ruby
def request
  hostname = 'localhost:50051'
  stub = Email::Emailer::Stub.new(hostname, :this_channel_is_insecure)
  email = Email::EmailRequest.new(title: "Greetings", body: "Greetings from WC champion Argentina.")
  email_response = stub.send_email(email)
end

n = 100
real_time = Benchmark.measure {
  n.times { request }
}.real

puts "Average: #{(real_time/n).round(3)}segs"
```

Se obtuvó el siguiente promedio:
``` 
Average: 5,506segs
``` 

Con este dato se creó un cliente con un deadline 10% menor que el promedio.
```ruby
def request
  hostname = 'localhost:50051'
  stub = Email::Emailer::Stub.new(hostname, :this_channel_is_insecure, timeout: 4.955)
  email = Email::EmailRequest.new(title: "Greetings", body: "Greetings from WC champion Argentina.")
  email_response = stub.send_email(email)

  puts "Success"
rescue GRPC::BadStatus => e
  puts "ERROR: #{e.message}"
end

10.times { request }
```

Se obtuvo los siguientes resultados:
```
client_1  | ERROR: 4:Deadline Exceeded. debug_error_string:{UNKNOWN:Deadline Exceeded {created_time:"2022-12-22T02:34:13.707967975+00:00", grpc_status:4}}
client_1  | ERROR: 4:Deadline Exceeded. debug_error_string:{UNKNOWN:Deadline Exceeded {created_time:"2022-12-22T02:34:18.663835377+00:00", grpc_status:4}}
client_1  | ERROR: 4:Deadline Exceeded. debug_error_string:{UNKNOWN:Deadline Exceeded {grpc_status:4, created_time:"2022-12-22T02:34:23.619869683+00:00"}}
client_1  | ERROR: 4:Deadline Exceeded. debug_error_string:{UNKNOWN:Deadline Exceeded {grpc_status:4, created_time:"2022-12-22T02:34:28.575837666+00:00"}}
client_1  | ERROR: 4:Deadline Exceeded. debug_error_string:{UNKNOWN:Deadline Exceeded {created_time:"2022-12-22T02:34:33.531841855+00:00", grpc_status:4}}
client_1  | ERROR: 4:Deadline Exceeded. debug_error_string:{UNKNOWN:Deadline Exceeded {created_time:"2022-12-22T02:34:38.487867761+00:00", grpc_status:4}}
client_1  | ERROR: 4:Deadline Exceeded. debug_error_string:{UNKNOWN:Deadline Exceeded {grpc_status:4, created_time:"2022-12-22T02:34:43.444267828+00:00"}}
client_1  | ERROR: 4:Deadline Exceeded. debug_error_string:{UNKNOWN:Deadline Exceeded {created_time:"2022-12-22T02:34:48.399629181+00:00", grpc_status:4}}
client_1  | ERROR: 4:Deadline Exceeded. debug_error_string:{UNKNOWN:Deadline Exceeded {grpc_status:4, created_time:"2022-12-22T02:34:53.356424105+00:00"}}
client_1  | ERROR: 4:Deadline Exceeded. debug_error_string:{UNKNOWN:Deadline Exceeded {grpc_status:4, created_time:"2022-12-22T02:34:58.311474507+00:00"}}
```

Una conclusión posible  es que gRPC es estable en su tiempo de respuesta, por lo que el desvio de la media en el tiempo de respuesta es menor al 10% y es improbable que una request se termine antes de dicho tiempo.

En parte estos resultados son causa de la relacion tiempo de procesamiento y tiempo de comunicacion, y que esto fue probado en un entorno local donde el tiempo de comunicacion es significativamente menor a un entorno de produccion.