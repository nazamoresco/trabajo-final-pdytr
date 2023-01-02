# Universidad Nacional de La PLata

## Licenciatura en Informática 

### Programación distribuida y en tiempo real

### gRPC con Ruby y Java

### Nazareno Moresco

## Propuesta
 
Se propusó como un trabajo final sobre gRPC en Ruby, este consistira de dos partes. una traduccion del TP3 a Ruby y una comparacion entre REST y gRPC en Ruby, el objetivo sera comparar en performance una API implementada con ambas tecnicas asi como realizar un juicio de valor de los codigos resultantes.

La entrega final incluirá:
* Entrega del TP3
* El codigo fuente de todas las implementaciones.
* Un Dockerfile para instalar y ejecutar el codigo fuente.
* Un manual de usuario para la instalacion y configuracion.
* Documentacion de lo realizado:
    * Justificacion de las desiciones
    * Explicacion del codigo
    * Conclusiones

Crear 3 clientes para el partido Argentina - Francia.
1. Un Commentator que acceda a Argentina - Francia y comente el partido.
2. Un Arbitro que acceda a Argentina - Francia y arbitre el partido.
3. Un listener que acceda a Argentina - Francia y escuche el partido.

## Traduccion del TP3 a Ruby

Durante la cursada tuvimos un ejemplo base, como se propone resolver el tp en otro lenguaje deberemos realizarlo nosotros mismos.

En este documento se explica como se llevo a cabo este ejemplo base.
[Base](puntos/base.md)


###  Ejercicios

1. [Ejercicio 1A - Errores de conectividad](puntos/ej1_a.md)
2. [Ejercicio 1B - Deadline](puntos/ej1_b.md)
3. [Ejercicio 1C - Promedio y deadlines](puntos/ej1_c.md)
4. [Ejercicio 2 - Tipos de API](puntos/ej2.md)
5. [Ejercicio 3 - Transparencia](puntos/ej3.md)
6. [Ejercico 4A - Sistema de archivos](puntos/ej4_a.md)
7. [Ejercicio 4B - Concurrencia](puntos/ej4_b.md)
8. [Ejercicio 5A - Tiempo de respuesta](puntos/ej5_a.md)
9. [Ejercicio 5B - Sockets](puntos/ej5_b.md)


### Comparacion API REST vs gRPC

En [este documento](puntos/comparacion.md) se encuentra una comparación entre dos implementaciones del mismo sistema, uno en gRPC y el otro en REST. 