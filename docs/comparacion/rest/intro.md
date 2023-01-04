## Idea para la implementación

Para implementar con REST en Ruby se eligio el framework Sinatra, si bien Rails es muy conocido es un exceso usarlo para este MVP. Sinatra es lo suficientemente minimalista para enfocarnos en la comunicacion y no en las especificidades de Rails.

Un problema a resolver sera el de las comunicaciónes Streaming, REST no soporta Streaming, ya que esta basado en HTTP/1 y este no tiene dicha funcionalidad.

En un entorno real mucho menos restrictivo que un enunciado, se podria resolver con el protocolo WebSocket como se hace en Hotwire (gema que ha ganado popularidad este último año), pero al no ser el caso se resolvió con la técnica de Polling. Este famoso concepto se aplica a las comunicaciónes web cuando un cliente se encarga de contactar al servidor periódicamente.

Un ejemplo para ilustrar:

 ____________________________________________________________________________________________
|    |  Datos       |  Server Streaming                         |  Polling                    |
|----|--------------|-------------------------------------------|-----------------------------|
| 1. |              |  S <- *"Notificame de nuevos datos"* - C  |  S <- *"Nuevos datos?"* - C |
| 2. |              |                                           |  S -> *No.* -> C            |
| 3. |  Nuevo dato! |  S - *Nuevo Dato* -> C                    |  S <- *"Nuevos datos?"* - C |
| 4. |              |                                           |  S - *Nuevo dato* -> C      |
|

S=Servidor, C=Cliente

A continuacion, [implementacion de listar partidos](listar-partidos.md)