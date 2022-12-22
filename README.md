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

## Traduccion del TP3 a Ruby

Durante la cursada tuvimos un ejemplo base, como se propone resolver el tp en otro lenguaje deberemos realizarlo nosotros mismos.

En este documento se explica como se llevo a cabo este ejemplo base.
[Base](puntos/base.md)

```
1. Utilizando como base el programa ejemplo1 de gRPC:
Mostrar experimentos donde se produzcan errores de conectividad del lado del
cliente y del lado del servidor.
```
```
a) Si es necesario realice cambios mínimos para, por ejemplo, incluir exit(), de
forma tal que no se reciban comunicaciones o no haya receptor para las
comunicaciones.
```

[Ejercicio 1A](puntos/ej1_a.md)


```
c) Reducir el deadline de las llamadas gRPC a un 10% menos del promedio
encontrado anteriormente. Mostrar y explicar el resultado para 10 llamadas.
``` 
[Ejercicio 1C](puntos/ej1_c.md)