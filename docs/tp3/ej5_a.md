# Ejercicio 5A
```
5) Tiempos de respuesta de una invocación
a) Diseñe un experimento que muestre el tiempo de respuesta mínimo de una invocación con gRPC. Muestre promedio y desviación estándar de tiempo respuesta.
```

El ejercicio se desarrolló en la carpeta `ej5_a`.

Se utilizó el código `base` por sus características mínimas para realizar el experimento.

De 100 iteraciones de comunicación se calcula el tiempo total, el promedio y desviación estándar.

```ruby
n = 100
real_times = n.times.map do
  Benchmark.measure { stub.send_email(email) }.real * 1000.0
end

total_time = real_times.sum
average = total_time / n
standard_deviation = Math.sqrt(real_times.sum { |real_time| (real_time - average) ** 2} / (n - 1))

puts "Total time: #{total_time.round(3)} ms"
puts "Average: #{average.round(3)} ms"
puts "Standard deviation: #{standard_deviation.round(3)} ms"
```

Finalmente estos son los resultados.
```
Total time: 47.037 ms
Average: 0.47 ms
Standard deviation: 0.234 ms
```

[Siguiente](ej5_b.md)

[Volver](../../README.md)

