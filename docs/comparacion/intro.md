# Comparando gRPC con REST

Para la comparación se planteó una situación ficticia donde se le pide a un grupo de desarrolladores un sistema implementado con REST y GRPC en Ruby.

## La idea

En el año 2026, FIFA ha encargado a un grupo de desarrolladores Ruby la implementación de un sistema de arbitraje super automatizado.

El sistema órbita alrededor dos módulos principales el Comentarista y el Árbitro.

El Comentarista es un cliente que se encarga de enviar al servidor todos los eventos, en altísima precisión, de un partido de fútbol, eventos que registra mediante las cámaras de los teléfonos de la tribuna y las cámaras de los distintos medios periodísticos. El objetivo a largo plazo es un nivel de detalle de los comentarios tal que sea suficiente para tareas como replicar el partido en tiempo real en una renderización 3D o la construcción de estadísticas en tiempo real para los DTs de los partidos.

El Árbitro es un módulo que reside en el servidor y escucha los comentarios, en caso de detectar una falta en el reglamento de football advierte a sistemas externos (fuera de scope en el MVP) y almacena la sanción en los Logs del servidor.

Finalmente, también existen los Oyentes, estos son clientes que escucharán los partidos relatados por el Comentarista y arbitrados por el Árbitro.

Lamentablemente el grupo de desarrolladores no ha logrado llegar a un consenso sobre la mejor tecnología a utilizar, REST o GRPC. La FIFA resolvió con la creación de dos MVPs, uno con cada tecnología, con la esperanza de que se logre resolver las diferencias.

## La Implementación

Se requieren las siguientes interacciones con el servidor:

1. Listar los partidos
   * Pueden existir distintos partidos simultáneos, los clientes deben ser capaces de listarlos.
   * El cliente pide listar los partidos.
   * El servidor devuelve los nombres de los partidos.
2. Escuchar los partido
   * El cliente envía un string que identifica al partido que quiere escuchar.
   * El server streamea los arbitrajes y comentarios que suceden.
   * En general, los oyentes usarán este endpoint.
3. Comentar los partidos
   * El cliente envía logs de los eventos del partido al server como strings.
   * El server registra y distribuye a los demás oyentes.
   * En general los Comentaristas usarán este endpoint.

## Índice

* [Implementación en gRPC](grpc/intro.md)
  * [Listar partidos](grpc/listar-partidos.md)
  * [Comentar partidos](grpc/comentar-partidos.md)
  * [Escuchar partidos](grpc/escuchar-partidos.md)
* [Implementación en REST](rest/intro.md)
  * [Listar partidos](rest/listar-partidos.md)
  * [Comentar partidos](rest/comentar-partidos.md)
  * [Escuchar partidos](rest/escuchar-partidos.md)
* [Balance final](balance.md)

[Volver](../../README.md)