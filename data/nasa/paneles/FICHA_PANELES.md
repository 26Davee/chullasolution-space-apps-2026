# Ficha de procedencia: irradiancia solar para los paneles de Killawasi

- **Conjunto de datos:** TSIS-1 TIM, Total Solar Irradiance, nivel 3, promedios de 24 horas (version 5 segun el encabezado del archivo)
- **Instrumento y mision:** Total Irradiance Monitor (TIM) del Total and Spectral Solar Irradiance Sensor (TSIS-1), a bordo de la Estacion Espacial Internacional
- **Publica:** LASP, Universidad de Colorado, para la NASA. Tambien se archiva en el GES DISC de la NASA
- **Pagina oficial:** https://lasp.colorado.edu/tsis/data/tsi-data/
- **Archivo descargado:** http://lasp.colorado.edu/data/tsis/tsi_data/tsis_tsi_L3_c24h_latest.txt
- **DOI:** https://doi.org/10.5067/TSIS/TIM/DATA306
- **Descargado por:** Anahi, 15/11/2026
- **Rango de fechas:** 2018-01-11 a 2026-11-10
- **Dias con medicion valida:** 2762 de 3227 filas. Se descartaron 465 filas sin medicion o fuera de rango
- **Unidad:** W/m2
- **Licencia / condiciones de uso:** Datos de la NASA de acceso abierto y sin restriccion, segun la guia de uso y citacion de EOSDIS (https://www.earthdata.nasa.gov/data/catalog/ges-disc-tsis-tsi-l3-24hr-05). Se debe citar el conjunto de datos.
- **Cita:** [COMPLETAR: copiar el texto de la seccion "Citation" de la pagina de Earthdata indicada arriba]

## Archivos
| Archivo | Que es |
|---|---|
| tsis_tsi_diario.txt | Descarga original, sin editar. No se sube al repositorio (pesa unos 488 KB) |
| tsi_diario.csv | Version reducida: solo las columnas que usa el juego |
| paneles_referencia.json | Resumen (minimo, maximo, promedio, variacion) |
| generar_paneles.ps1 | Script que genera los dos archivos anteriores desde el original |

## Columnas usadas
| Columna del archivo | Significado | En tsi_diario.csv |
|---|---|---|
| nominal_date_yyyymmdd | Fecha (YYYYMMDD) | fecha |
| tsi_1au | Irradiancia solar total a 1 UA, W/m2 | tsi_1au_wm2 |
| tsi_true_earth | Irradiancia a la distancia real de la Tierra, W/m2 | tsi_tierra_wm2 |
| provisional_flag | 1 = dato provisional, 0 = final | provisional |

## Resultados del resumen
| Medida | Minimo | Maximo | Promedio | Variacion pico a pico |
|---|---|---|---|---|
| Irradiancia a 1 UA (el Sol mismo) | 1360,29 | 1363,69 | 1362,07 W/m2 | 0,25 % |
| Irradiancia a la distancia de la Tierra | 1316,32 | 1409,56 | 1360,51 W/m2 | 6,85 % |

La variacion de 0,25 % a 1 UA es la del Sol. La de 6,85 % en la distancia de la Tierra viene de que la distancia al Sol cambia durante el ano, y no se usa para justificar los paneles.

## Como se usa en el juego
No cambia ningun numero de la simulacion. Respalda que un panel produzca una cantidad constante de dia y nada de noche: el Sol cambia muy poco de un dia a otro. Los valores de produccion del juego (0,6 por segundo, 0,75 con Superpaneles) son valores de prueba, decisiones de diseno.

## Limites
- El archivo se midio en orbita terrestre (Estacion Espacial Internacional), no en la Luna. La Luna esta a una distancia del Sol casi igual a la de la Tierra.
- Los datos son de la luz total del Sol. No se afirma cuanta energia produciria un panel real en una base lunar.
