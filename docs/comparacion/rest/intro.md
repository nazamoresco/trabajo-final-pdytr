## Idea para la implementación

Para implementar con REST en Ruby se eligio el framework Sinatra, si bien Rails es muy conocido es un exceso usarlo para este MVP. Sinatra es lo suficientemente minimalista para enfocarnos en la comunicacion y no en las especificidades de Rails.

Para las comunicaciones con streaming, REST cuenta con streaming gracias a HTTP/1.1 y Sinatra provee de metodos para aprovecharlo.
```ruby
get '/stream', provides: 'text/event-stream' do
  stream :keep_open do |out|
    out << "hola"
    sleep(0.5)
    out << "en el medio"
    sleep(0.5)
    out << "bye"
  end
end
```

Y con este cliente:
```ruby
Net::HTTP.start 'localhost', 4567 do |http|
  request = Net::HTTP::Get.new "/stream"
  http.request request do |response|
    response.read_body do |part|
      puts part
    end
  end
end
```

Observar la captura de Wireshark, como existe un unico TCP handshake.
```ruby
15	2.935232	::1	::1	TCP	76	52448 → 4567 [SYN] Seq=0 Win=65535 Len=0 MSS=65475 WS=256 SACK_PERM
16	2.935269	::1	::1	TCP	76	4567 → 52448 [SYN, ACK] Seq=0 Ack=1 Win=65535 Len=0 MSS=65475 WS=256 SACK_PERM
17	2.935287	::1	::1	TCP	64	52448 → 4567 [ACK] Seq=1 Ack=1 Win=2160640 Len=0
18	2.935470	::1	::1	HTTP	4606	GET /stream HTTP/1.1
19	2.935486	::1	::1	TCP	64	4567 → 52448 [ACK] Seq=1 Ack=4543 Win=2156032 Len=0
20	3.139720	::1	::1	TCP	200	4567 → 52448 [PSH, ACK] Seq=1 Ack=4543 Win=2156032 Len=136 [TCP segment of a reassembled PDU] # aca entro "hola"
21	3.139738	::1	::1	TCP	64	52448 → 4567 [ACK] Seq=4543 Ack=137 Win=2160384 Len=0
24	3.649615	::1	::1	TCP	80	4567 → 52448 [PSH, ACK] Seq=137 Ack=4543 Win=2156032 Len=16 [TCP segment of a reassembled PDU] # aca entro "en el medio"
25	3.649645	::1	::1	TCP	64	52448 → 4567 [ACK] Seq=4543 Ack=153 Win=2160384 Len=0
32	3.939240	::1	::1	HTTP	77	HTTP/1.1 200 OK  (text/event-stream) # aca entro "bye"
33	3.939270	::1	::1	TCP	64	52448 → 4567 [ACK] Seq=4543 Ack=166 Win=2160384 Len=0
```

A continuacion, [implementacion de listar partidos](listar-partidos.md)
