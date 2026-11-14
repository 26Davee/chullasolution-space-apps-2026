# Quién toca qué

**Un solo archivo manda sobre esto.** Si otro documento dice algo distinto, vale este.

Regla: **cada carpeta tiene un solo dueño.** Solo el dueño cambia sus archivos. Si necesitas algo en la carpeta de otra persona, se lo pides en el grupo o abres un Pull Request y el dueño lo aprueba.

## Mapa de carpetas

| Carpeta o archivo | Dueño | Qué va ahí |
|---|---|---|
| `project.godot`, `scenes/main.tscn` | **Puesto 1** | Configuración del proyecto y escena principal. Solo el puesto 1 los toca. |
| `core/` | **Puesto 1** | Arranque del juego y el script que conecta las partes. |
| `scenes/` | **Puesto 1** | Escenas de integración. |
| `export/` | **Puesto 1** | Ajustes de exportación a la web (`export_presets.cfg`) y notas de publicación. |
| `docs/` (menos `docs/registro/`) | **Puesto 1** | Documentación del equipo. |
| `.github/`, `README.md`, `CONTRIBUTING.md`, `.gitignore`, `.gitattributes` | **Puesto 1** | Organización del repositorio. |
| `simulation/` | **Puesto 2** | El modelo de la base: energía, vida, escudo. Incluye `simulation/tests/`. |
| `data/nasa/` | **Puesto 2** | Instantáneas reducidas de datos de NASA, con su etiqueta. |
| `world/` | **Puesto 3** | La Luna, el domo, la luz y los módulos (`world/moon_world.tscn`). |
| `assets/3d/` | **Puesto 3** | Modelos, texturas y arte del mundo. |
| `camera/` | **Puesto 4** | Cámara: girar, acercar, mover. |
| `interaction/` | **Puesto 4** | Seleccionar y colocar módulos, respuesta de cada acción. |
| `assets/audio/` | **Puesto 4** | Sonidos y música, con su licencia anotada. |
| `progression/` | **Puesto 5** | Misiones, reporte, árbol de mejoras y regeneración. |
| `data/missions/` | **Puesto 5** | Datos de las misiones y de las mejoras. |
| `ui/` | **Puesto 6** | Interfaz: barras, alertas, tutorial, modos (`ui/hud.tscn`). |
| `i18n/` | **Puesto 6** | Textos en inglés y español, como claves de traducción. |
| `assets/ui/` | **Puesto 6** | Iconos y tipografías. |
| `submission/` | **Puesto 6** | Póster, textos en inglés del envío y capturas. Los puestos 1 y 3 ayudan por Pull Request. |
| `docs/registro/puesto-N.md` | **Puesto N** | El registro personal de cada uno (IA, terceros, datos). |

## Quiero… → va en…

Si dudas dónde poner algo, busca aquí primero.

| Quiero… | Va en | Es del puesto |
|---|---|---|
| Cambiar cómo baja la energía, el agua o el escudo | `simulation/` | 2 |
| Agregar un dato de NASA | `data/nasa/` y anotarlo en tu registro | 2 |
| Cambiar cómo se ve la Luna, el domo o un módulo | `world/` | 3 |
| Agregar un modelo o una textura | `assets/3d/` | 3 |
| Cambiar cómo se mueve o se acerca la cámara | `camera/` | 4 |
| Que un clic haga algo | `interaction/` | 4 |
| Agregar un sonido o música | `assets/audio/` | 4 |
| Crear o ajustar una misión | `progression/` y `data/missions/` | 5 |
| Cambiar el costo de una mejora del árbol | `data/missions/` | 5 |
| Cambiar una barra, un botón o una pantalla | `ui/` | 6 |
| Escribir o traducir un texto | `i18n/` (pide la clave en el grupo) | 6 |
| Agregar un icono o una tipografía | `assets/ui/` | 6 |
| El póster o los textos del envío | `submission/` (1 y 3 ayudan por Pull Request) | 6 |
| Conectar mi escena al juego | Se lo pides al puesto 1 (`scenes/main.tscn`) | 1 |
| Exportar la versión web | `export/` | 1 |
| Anotar lo que usé de IA, de terceros o de NASA | `docs/registro/puesto-N.md` | tú |
| Cambiar un contrato entre puestos | Avisa en el grupo; se edita `docs/CONTRATOS.md` con los dos lados de acuerdo | 1 |

## Quién se coordina con quién

| Puesto | Pareja de revisión | Habla más con |
|---|---|---|
| 1 Integración | 6 | todos |
| 2 Ciencia | 5 | 5 y 6 |
| 3 Mundo | 4 | 4 y 6 |
| 4 Interacción | 3 | 3 y 6 |
| 5 Misiones | 2 | 2 y 6 |
| 6 Interfaz | 1 | todos |

## Quién es quién

Puestos confirmados el sábado 14 de noviembre. Falta el usuario de GitHub de cada persona: el puesto 1 lo anota y activa el `CODEOWNERS`.

| Puesto | Persona | Usuario de GitHub |
|---|---|---|
| 1 | Ángel David Espinoza Ureta | `26Davee` |
| 2 | Anahi | (pendiente) |
| 3 | Carlos Valladares | (pendiente) |
| 4 | Nicolas Ladino | (pendiente) |
| 5 | Gael | (pendiente) |
| 6 | Andrea | (pendiente) |

## Lo que nunca va en el repositorio

Contraseñas, llaves de API, tokens, datos personales, fotos o voces de menores, el logo de NASA, y archivos de otros que no tengan licencia que lo permita.

## Si no estás seguro de dónde va algo

Pregunta en el grupo antes de crear la carpeta. Una carpeta nueva con el dueño equivocado es lo que más choques causa.
