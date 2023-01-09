# La implementación de gPC

El ejercicio se desarrolla en la carpeta `comparacion/grpc`.

Se modificó la estructura de los archivos en el código respecto a los ejercicios anteriores. Se intenta plantear un ejemplo más de producción donde el cliente no debería tener acceso a los archivos del servidor, como ocurre en previos ejercicios.

Se decidió la siguiente estructura:
```
|_ lib/ ~ archivos generados por grpc
|_ listener/ ~ código del listener
|_ matches/ ~ contiene los archivos de los matches
|_ protos/ ~ contiene los protos
|_ server/ ~ contiene el código del server
```

[Siguiente](listar-partidos.md)

[Volver](../intro.md)

