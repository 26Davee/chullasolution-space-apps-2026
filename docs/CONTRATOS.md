# Contratos entre puestos

Un contrato es un acuerdo corto sobre **qué datos se pasan entre dos partes y con qué nombre**. Mientras se respete, cada puesto puede trabajar sin esperar a los demás.

Se completan el sábado a las 10:15, entre todos. Después, **cambiar un contrato requiere avisar en el grupo y que acepten los dos lados.** Dueño del archivo: puesto 1.

## 1. Estado de la base (puesto 2 → todos)

Qué números circulan y con qué nombre. Todos son **unidades de juego**, salvo que se indique fuente.

| Nombre | Qué es | Unidad | Rango |
|---|---|---|---|
| | | | |

## 2. Acciones (puesto 4 → puesto 2)

Qué le pide el jugador a la simulación.

| Acción | Qué pide | Quién la ejecuta |
|---|---|---|
| | | |

## 3. Eventos de misión (todos → puesto 5)

Cómo avisa el juego que algo pasó, para que una misión lo cuente.

| Evento | Cuándo se emite | Datos que lleva |
|---|---|---|
| | | |

## 4. Textos (todos → puesto 6)

Ningún texto visible va escrito fijo en el código: se usa una clave de traducción que vive en `i18n/`.

| Regla | Ejemplo |
|---|---|
| Formato de clave | `area.nombre` |
| Quién crea la clave | quien la usa, pidiéndola en el grupo |
| Quién escribe el texto | puesto 6 |

## 5. Escenas que se conectan (todos → puesto 1)

| Escena | Dueño | Se conecta en |
|---|---|---|
| `world/moon_world.tscn` | 3 | `scenes/main.tscn` |
| `ui/hud.tscn` | 6 | `scenes/main.tscn` |
| | | |

## Firmas

| Contrato | Puesto | Puesto | Hora |
|---|---|---|---|
| 1 | | | |
