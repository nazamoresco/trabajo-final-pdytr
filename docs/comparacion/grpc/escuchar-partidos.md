
# Escuchar partidos

Para este endpoint, se utilizó server streaming, el cliente envía el partido que quiere escuchar y el servidor streamea los eventos como strings.

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
}
```

En el listener se realizó una pequeña modificación luego de listar los partidos, se selecciona el primero y hace una petición para escucharlo.
```ruby
response = stub.list_matches Football::ListMatchesRequest.new
my_match = response.matches.first

call = stub.listen_match(Football::ListenMatchRequest.new(match: my_match))

call.each do |event_res|
  puts event_res.event
  break if event_res.match_over
end
```

En el servidor, se *stremea* desde la clase `MatchListener`
```ruby
class Server < Football::Football::Service
  def listen_match(listen_req, _unused_call)
    MatchListener.new(listen_req.match).each
  end
end
```

La clase `MatchListener` accede al archivo correspondiente del partido y streamea los eventos en él al cliente.
El enumerador que se construyó es distinto a los de ejercicio anteriores, ya que no itera por datos, escucha a un archivo, por esta razón se explica en mayor detalle el método `each` más adelante.

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
          event: next_line
        )
      end
    end

    real_time_match_listener.each { |result| yield result }
  end
end
```

Normalmente un enumerador se ve así en Ruby:
```ruby
100.times
datos.each
file.each_line
```

Estas formas tienen en común que se evalúa los datos a recorrer antes de crear el enumerador. El rango numérico debe ser evaluado, los datos construidos y el archivo abierto. Pero en este problema se necesita acceder a nuevos datos que pueden aparecer una vez evaluado nuestro enumerador.
Por esto se utilizó este método:

```ruby
  real_time_match_listener = Enumerator.new do
    # inicialización

    loop do
      # siguiente cosa a devolver
    end
  end
```

Se construye una especie de enumerador "infinito", la lógica para cada nuevo elemento se encuentra en el bloque `loop` , cuenta con un estado definido en `inicialización` y es posible finalizar la iteración levantando una excepción en `loop` (`StopIteration`).

En la inicialización se abre el archivo por primera vez y se crea una variable para hacer un seguimiento de los bytes leídos.

```ruby
  real_time_match_listener = Enumerator.new do
    lines = File.open("matches/#{@match}", "r").each_line
    already_read_bytes = 0

    loop do
      # siguiente cosa a devolver
    end
  end
```

Finalmente se generó la lógica para construir el siguiente elemento.
Puntos a observar:
* Si existen aún líneas para leer de el archivo abierto, se lee y actualiza los bytes leídos.
* Si no existen líneas para leer:
  * Se espera 1 segundo.
  * Se abre nuevamente el archivo para acceder al nuevo contenido, pero se mueve el puntero del archivo a la última posición leída.
  * Se realiza 10 veces esta lógica, en caso de no encontrar nuevo contenido, se considerará finalizado el partido.

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

[Ir a la implementación de rest.](../rest/intro.md)

[Volver al indice.](../intro.md)

