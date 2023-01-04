
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

[Ir a la implementacion de rest.](../rest/intro.md)

[Volver al indice.](../intro.md)