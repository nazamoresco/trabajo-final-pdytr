# gRPC - Trabajo final
### Nazareno Moresco - Licenciatura en Informática -  Universidad Nacional de La Plata

## Propuesta

*"Se propone un trabajo final sobre gRPC en Ruby, este consistirá de dos partes. una traduccion del TP3 a Ruby y una comparacion entre REST y gRPC en Ruby, el objetivo será comparar en performance una API implementada con ambas tecnicas asi como realizar un juicio de valor de los codigos resultantes.*

*La entrega final incluirá:*
* *Entrega del TP3*
* *El codigo fuente de todas las implementaciones.*
* *Un Dockerfile para instalar y ejecutar el codigo fuente.*
* *Un manual de usuario para la instalacion y configuracion.*
* *Documentacion de lo realizado:*
    * *Justificacion de las desiciones*
    * *Explicacion del codigo*
    * *Conclusiones*

*"*


## Traducción del TP3 a Ruby

Durante la cursada se contó con un ejemplo base, como se propone resolver el tp en otro lenguaje se deberá reimplementar.

En este documento se explica como se llevo a cabo este ejemplo base.
[Base](docs/tp3/base.md)

### Como ejecutar un ejercicio?

Todos los ejercicios se encuentra dockerizados, para ejecutar uno simplemente debemos dirijirnos a la carpeta y ejecutar `docker-compose up`.
Se necesitara de instalar herramientas como `docker-compose` y `docker`.

###  Ejercicios

1. [Ejercicio 1A - Errores de conectividad](docs/tp3/ej1_a.md)
2. [Ejercicio 1B - Deadline](docs/tp3/ej1_b.md)
3. [Ejercicio 1C - Promedio y deadlines](docs/tp3/ej1_c.md)
4. [Ejercicio 2 - Tipos de API](docs/tp3/ej2.md)
5. [Ejercicio 3 - Transparencia](docs/tp3/ej3.md)
6. [Ejercico 4A - Sistema de archivos](docs/tp3/ej4_a.md)
7. [Ejercicio 4B - Concurrencia](docs/tp3/ej4_b.md)
8. [Ejercicio 5A - Tiempo de respuesta](docs/tp3/ej5_a.md)
9. [Ejercicio 5B - Sockets](docs/tp3/ej5_b.md)


### Comparacion API REST vs gRPC

En [este documento](docs/comparacion/intro.md) se encuentra la comparación entre dos implementaciones del mismo sistema, uno en gRPC y el otro en REST.