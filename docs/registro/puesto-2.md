# Registro del puesto 2 · Ciencia, simulación y datos

**Persona:** Anahí Tixe  
**Usuario de GitHub:** <!-- escribe aquí tu usuario de GitHub -->

Este archivo registra las actividades realizadas individualmente en el puesto 2.

## 1. Uso de IA

| Fecha y hora | Qué hice con IA (código, texto, imagen, sonido) | Herramienta | Dónde quedó (archivo) | Qué revisé o cambié yo |
|---|---|---|---|---|
| 14/11/2026 | Recibí ayuda para elaborar y revisar el script de PowerShell que procesa los archivos CSV de NASA y genera los parámetros de las tormentas. | ChatGPT | `data/nasa/generar_tormentas.ps1` | Revisé el código, ejecuté el script en PowerShell y comprobé los resultados obtenidos. |
| 14/11/2026 | Recibí ayuda para organizar y redactar la ficha de procedencia de los datos científicos. | ChatGPT | `data/nasa/FICHA_PROCEDENCIA.md` | Revisé la información de los archivos, la fuente de NASA, la variable utilizada y su unidad de medida. |
| 14/11/2026 | Recibí ayuda para redactar el registro de actividades del puesto 2. | ChatGPT | `docs/registro/puesto-2.md` | Revisé que las actividades descritas correspondieran al trabajo realizado. |

## 2. Material de terceros

| Qué es | Autor | Dónde lo conseguí (enlace) | Licencia | Dónde se usa |
|---|---|---|---|---|
| Datos de radiación absorbida del instrumento CRaTER (LRO). | NASA | https://visualization.osdr.nasa.gov/radlab/ | Según la política de información científica de NASA SMD. | `data/nasa/radlab_2021-10-28.csv`, `data/nasa/radlab_2017-09-10.csv`, `data/nasa/radlab_2012-01-24.csv` |

## 3. Datos de NASA

| Dato | Enlace oficial | Fecha de descarga | Unidades | Qué le hice (reducir, convertir…) | Dónde se usa |
|---|---|---|---|---|---|
| Mediciones de tasa de dosis absorbida del instrumento CRaTER, nave LRO, periodo de octubre de 2021. | https://visualization.osdr.nasa.gov/radlab/ | 14/11/2026 | µGy/hour | Se extrajeron las columnas `timestamp` y `absorbed_dose_rate`, se identificó el valor máximo y se calcularon parámetros para el juego. | `data/nasa/radlab_2021-10-28_reducido.csv` y `data/nasa/tormentas_juego.json` |
| Mediciones de tasa de dosis absorbida del instrumento CRaTER, nave LRO, periodo de septiembre de 2017. | https://visualization.osdr.nasa.gov/radlab/ | 14/11/2026 | µGy/hour | Se extrajeron las columnas `timestamp` y `absorbed_dose_rate`, se identificó el valor máximo y se calcularon parámetros para el juego. | `data/nasa/radlab_2017-09-10_reducido.csv` y `data/nasa/tormentas_juego.json` |
| Mediciones de tasa de dosis absorbida del instrumento CRaTER, nave LRO, periodo de enero de 2012. | https://visualization.osdr.nasa.gov/radlab/ | 14/11/2026 | µGy/hour | Se extrajeron las columnas `timestamp` y `absorbed_dose_rate`, se identificó el valor máximo y se calcularon parámetros para el juego. | `data/nasa/radlab_2012-01-24_reducido.csv` y `data/nasa/tormentas_juego.json` |

## 4. Aclaraciones

- No se utilizó DONKI; los datos científicos se obtuvieron de NASA RadLab (OSDR).
- Los valores originales de `absorbed_dose_rate` se conservaron en los CSV reducidos, sin convertir sus unidades.
- La intensidad, duración y momento de aparición de las tormentas dentro del videojuego son parámetros calculados o definidos para la simulación. Cuando se expresan como valores propios del juego, corresponden a **unidades de juego**, no a unidades científicas de NASA.
- La descarga de octubre de 2021 está pendiente de completar la ventana temporal solicitada del 28 al 30 de octubre.
