# Comentar partidos

Para comentar partidos, se implementó un client streaming.

Para ello en el cliente, se crea una conexión persistente HTTP 1.1 keep-alive con el metodo `persistent`.
Una vez realizado el handshake de TCP, se streamea los comentarios de la clase `Commentator` (permanece sin modificacion de su implementacion en gRPC).

```ruby
require "json"
require "http"
require_relative "commentator"

response = HTTP.get("http://localhost:4567/list-matches").parse
matches = response["matches"]

match = matches[0]
commentator = Commentator.new(
  local: match.split("-")[0],
  visitor: match.split("-")[1]
)

begin
  http = HTTP.persistent "http://localhost:4567"

  100.times { http.put("/comment-match/#{match}", json: { comment: commentator.comment }).flush }
ensure
  http.close if http
end
```

En el servidor se define un nuevo endpoint con la acción definida como PUT ya que modifica lo logs del partido.
La lógica interior es identica a la de gRPC, simplemente se trabaja con json en vez de utilizar las clases proveidas por gRPC.
```ruby
put '/comment-match/:match_id', provides: "application/json" do
  match = params["match_id"]
  comment = JSON.parse(request.body.read)["comment"]

  referee = Referee.new
  File.open("matches/#{match}", "a") do |file|
    file << "#{comment}\n"

    santion = referee.observe(comment)
    file << "#{santion}\n" unless santion.nil?
  end

  {}.to_json
end
```

A continuación, [escuchar partidos](escuchar-partidos.md)
