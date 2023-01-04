### Escuchar partidos

El servidor streamea los contenidos de los partidos de forma similar a gRPC, esto es se devuelve un enumerador de Ruby que ira devolviendo resultados parciales.
Notar el tipo de respuesta `text/event-stream`.
`MatchListener` se mantiene igual con una pequeña modificacion, se devuelve un JSON en vez de una clase generada de gRPC.
```ruby
# file comparacion/rest/server/server.rb
get '/listen-match/:match_id', provides: 'text/event-stream' do
  MatchListener.new(params["match_id"])
end
```

En el cliente, simplemente se escucha a este stream y se imprime los resultados.
```ruby
response = HTTP.get("http://localhost:4567/listen-match/#{match}")
response.body.each { |x| puts x }
```

A continuación [balance final](../balance.md).