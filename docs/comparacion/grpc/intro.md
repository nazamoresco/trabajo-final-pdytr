## La implementancion de gRPC

El ejercicio se desarrolla en la carpeta `comparacion/grpc`.

Se ha modificó la estructura de los archivos en el código respecto a los ejercicios anteriores. Se intenta plantear un ejemplo mas de produccion donde el cliente no deberia tener acceso a los archivos del server, como ocurre en previos ejercicios.

Se decidío la siguiente estructura:
```
|_ lib/ ~ archivos generados por grpc
|_ listener/ ~ codigo del listener
|_ matches/ ~ contiene los archivos de los matches
|_ protos/ ~ contine los protos
|_ server/ ~ contiene el codigo del server
```

A continuacion, [implementacion de listar partidos](listar-partidos.md)