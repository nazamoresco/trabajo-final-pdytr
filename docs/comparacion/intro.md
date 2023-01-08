# Comparando gRPC con REST

Para la comparación se planteó una situación ficticia donde se le pide a un grupo de desarrolladores un sistema impementado con REST y gRPC en Ruby.

## La idea

Es el año 2026, FIFA ha encargado a un grupo de desarrolladores Ruby la implementación de un sistema de arbitraje super automatizado.

El sistema orbita alrededor dos módulos principales el Comentarista y el Árbitro.

El Comentarista es un cliente que se encarga de enviar al servidor todos los eventos, en altisima precisión, de un partido de football, eventos que registra mediante las cámaras de los telefonos de la tribuna y las cámaras de los distintos medios periodísticos. El objetivo a largo plazo es un nivel de detalle de los comentarios tal que sea suficiente para tareas como replicar el partido en tiempo real en una renderización 3D o la construcción de estadísticas en tiempo real para los DTs de los partidos.

El Árbitro es un módulo que reside en el servidor y escucha los comentarios, en caso de detectar una falta en el reglamento de football advierte a sistemas externos (fuera de scope en el MVP) y almacena la sanción en los Logs del servidor.

Finalmente, tambien existen los Oyentes, estos son clientes que escucharan los partidos relatados por el Comentarista y arbitrados por el Árbitro.

Lamentablemente el grupo de desarrolladores no ha logrado llegar a un consenso sobre la mejor tecnologia a utilizar, REST o gRPC. FIFA resolvió con la creacion de dos MVPs, uno con cada tecnologia, con la esperanza de que se logre resolver las diferencias.

## La Implementacion

Se requiren las siguientes interacciones con el servidor:

1. Listar los partidos
   * Pueden existir distintos partidos simultaneos, los clientes debe ser capaces de listarlos.
   * El cliente pide listar los partidos.
   * El server devuelve los nombres de los partidos.
2. Escuchar los partido
   * El cliente envia un string que identifica al partido que quiere escuchar.
   * El server streamea los arbitrajes y comentarios que suceden.
   * En general, los Oyentes usaran este endpoint.
3. Comentar los partidos
   * El cliente envia logs de los eventos del partido al server como strings.
   * El server registra y distribuye a los demas oyentes.
   * En general los Comentaristas usaran este endpoint.

* [Implementacion en gRPC](grpc/intro.md)
  * [Listar partidos](grpc/listar-partidos.md)
  * [Comentar partidos](grpc/comentar-partidos.md)
  * [Escuchar partidos](grpc/escuchar-partidos.md)
* [Implementacion en REST](rest/intro.md)
  * [Listar partidos](rest/listar-partidos.md)
  * [Comentar partidos](rest/comentar-partidos.md)
  * [Escuchar partidos](rest/escuchar-partidos.md)
