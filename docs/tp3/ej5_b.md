# Ejercicio 5B
```
5) Tiempos de respuesta de una invocación
b) Utilizando los datos obtenidos en la Práctica 1 (Socket) realice un análisis de los tiempos y sus diferencias. Desarrollar una conclusión sobre los beneficios y complicaciones tiene una herramienta sobre la otra.
```
El ejercicio se desarrolló en la carpeta `ej5_b`.
 
No sería correcto comparar con los datos de la Práctica 1 de la cursada ya que estos utilizan una plataforma Java. Por lo que se decidió implementar un ejemplo sencillo y tomar los tiempos.
 
Para implementar el Socket se definió un "protocolo" de "palabra", el cliente envía el título y cuerpo del email primero, y luego el servidor le envía el booleano de éxito y un mensaje.
 
El servidor recibirá 100 mensajes del cliente para sacar el promedio y luego cierra el socket:
```ruby
require 'socket'
 
server = TCPServer.new 50051 # Server bound to port 50051
 
loop do
  client = server.accept    # Wait for a client to connect
 
  100.times do
    client.gets # Title
    client.gets # Body
    client.puts true
    client.puts "Your email is ok."
  end
 
  client.close
end
```
 
El cliente abrirá el socket, realiza 100 comunicaciones, y luego calcula los estadísticos.
```ruby
require 'socket'
require 'benchmark'
 
def request(server)
  server.puts "Title - My email title"
  server.puts "Body - My email body"
 
  server.gets # Success
  server.gets # Message
end
 
server = TCPSocket.new 'localhost', 50051
 
n = 100
real_times = n.times.map do
  Benchmark.measure { request(server) }.real * 1000.0
end
 
server.close
 
total_time = real_times.sum
average = total_time / n
standard_deviation = Math.sqrt(real_times.sum { |real_time| (real_time - average) ** 2} / (n - 1))
 
puts "Total time: #{total_time.round(3)} ms"
puts "Average: #{average.round(3)} ms"
puts "Standard deviation: #{standard_deviation.round(3)} ms"
```
 
Los resultados fueron los siguientes:
```
client_1  | Total time: 9.927 ms
client_1  | Average: 0.099 ms
client_1  | Standard deviation: 0.175 ms
```
 
Se recuerdan los resultados en gRPC:
```
Total time: 47.037 ms
Average: 0.47 ms
Standard deviation: 0.234 ms
```
 
## Balance final
 
Se ve que el algoritmo que utiliza Sockets es más rápido que el de gRPC.
Una explicación es que en gRPC las comunicaciones esperan una respuesta, son bidireccionales, a diferencia del uso de Sockets donde las comunicaciones pueden ser unilaterales, sin la necesidad de esperar una respuesta del otro par.
 
El mayor beneficio que provee el uso de Sockets sobre el uso de gRPC es la velocidad, sin embargo, gRPC resulta más atractivo en la implementación de algoritmos más complejos ya que permite abstraerse de mejor manera de las tecnicalidades de las comunicaciones, además que provee una estructura más sólida *out of the box* a la hora de encarar un proyecto grande en comparación a sockets.
 
[Volver](../../README.md)


