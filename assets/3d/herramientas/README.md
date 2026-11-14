# Kit de arte de Killawasi (versión 2)

Las piezas de `assets/3d/` se generan con código. No hay texturas ni modelos de terceros: todo es geometría procedural con la paleta de la guía visual.

## Archivos

| Archivo | Qué contiene |
|---|---|
| `killawasi_kit.gd` | Paleta, materiales compartidos, mallas redondeadas (caja, torno, tubo, placa) y fusión de mallas. |
| `piezas_base.gd` | Cápsula, domo, panel solar, procesador de hielo y tanque de agua. |
| `piezas_modulos.gd` | Generador de oxígeno, reciclador, jardín, batería y rover. |
| `piezas_personajes.gd` | Astronauta y vicuña, con sus poses. |
| `piezas_herramientas.gd` | Pala, pico, taladro manual y taladro con mochila. |
| `piezas_entorno.gd` | Suelo, rocas, montañas, cráteres, cristales, tormenta, Tierra, Sol, estrellas, ambiente y escenas de `world/`. |
| `generar_killawasi_v2.gd` | Escribe las escenas `.tscn` y los `.glb`. |

`killawasi_modelos.gd`, `generar_procesador_hielo.gd` y `lowpoly.gd` son de la versión 1. **No los ejecutes**: sobrescriben las escenas nuevas.

## Regenerar

Desde la carpeta del proyecto, con Godot 4.7.2 Standard:

```
godot --headless --path . --script res://assets/3d/herramientas/generar_killawasi_v2.gd
godot --headless --path . --script res://assets/3d/herramientas/generar_killawasi_v2.gd -- rover tanque
godot --headless --path . --script res://assets/3d/herramientas/generar_killawasi_v2.gd -- glb
```

La primera línea genera todo, la segunda solo las piezas nombradas y la tercera exporta los GLB. No edites a mano los `.tscn` generados: cambia la función de la pieza y vuelve a generar.

## Reglas de las piezas

- Pivote en el suelo, centrado. Módulos y personajes miran hacia −Z. La cápsula conserva su puerta hacia +Z, como en la versión 1.
- Los colores salen solo de `PALETA`; cada material se guarda una vez en `assets/3d/materiales/`.
- Se conservan los nombres de la versión 1 que usan otras escenas: pivotes del astronauta y la vicuña, `Poses`, `Acceso`, `Leg0–3/Arm/Foot`, `NivelAgua`, `MarcadorEntrada`, `MarcadorSalida`, `MarcadorAcople`, `RuedaIzq1–3`, `RuedaDer1–3`, `Carga`, `Escudo`, `Borde`, `Indicador`.
- Las mallas que no se animan se funden por material para reducir llamadas de dibujado. Las que el juego mueve u oculta por nombre están en `CONSERVAR` dentro del kit.

## Lo nuevo que pueden usar otros puestos

- `world/ambiente_lunar.tscn`: luz, cielo, Tierra, Sol y estrellas. `set_noche(true)` hace la transición a la noche.
- `assets/3d/domo_lunar.tscn`: `set_escudo(valor)` de 0 a 100 cambia el aspecto en cuatro niveles.
- `world/moon_world.tscn`: escena lunar montada (ambiente, terreno, cápsula, domo, módulos, cráter de hielo, rover y camino).

## Licencias artísticas

La Tierra y el Sol del ambiente están agrandados para que se lean en pantalla y sus continentes son un dibujo, no un mapa. La intro de aterrizaje conserva el tamaño aparente calculado por el puesto 3. Las estrellas se ven de día y la luz principal no coincide con la posición del disco solar.
