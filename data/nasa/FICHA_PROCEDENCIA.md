# Ficha de procedencia: tormentas solares para Killawasi

- **Conjunto de datos:** CRaTER (Cosmic Ray Telescope for the Effects of Radiation), nave LRO, orbita lunar
- **Publica:** NASA, a traves de RadLab (OSDR)
- **Enlace:** https://visualization.osdr.nasa.gov/radlab/
- **Descargado por:** Anahi, 14/11/2026
- **Licencia / condiciones de uso:** [COMPLETAR: copiar de la pagina de NASA]
- **Unidad de absorbed_dose_rate:** [COMPLETAR: confirmar en RadLab]

## Archivos
Reducidos de la descarga original: se conservan solo timestamp y absorbed_dose_rate. Los valores no se alteraron.

| Archivo | Direccion de descarga original | Filas |
|---|---|---|
| radlab_2021-10-28_reducido.csv |  | 19 |
| radlab_2017-09-10_reducido.csv |  | 92 |
| radlab_2012-01-24_reducido.csv |  | 51 |

## Columnas
| Columna | Significado |
|---|---|
| timestamp | Fecha y hora de la medicion (UTC) |
| absorbed_dose_rate | Radiacion absorbida por hora |

## Como se usa en el juego
El pico de cada tormenta define la intensidad de una nube (entre 1,0 y 1,5, en escala logaritmica). El golpe al escudo es el golpe base del modo multiplicado por esa intensidad. La duracion sale de las horas en que la dosis estuvo sobre 10 veces el nivel normal.

Los picos son datos reales de CRaTER en orbita lunar. El momento en que llegan al juego, la intensidad y la duracion son decisiones del juego. CRaTER mide en detectores de silicio: no se afirma cuanta radiacion recibiria un astronauta.