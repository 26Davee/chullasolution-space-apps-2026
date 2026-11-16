# Revisión de modelos de Killawasi

> **Note:** these sheets were used to review scale and style during development. Some include AI-generated concept art used only as visual reference; those images are marked "IA" and are not part of the game. See `docs/AI_USE.md`.


## Versión 2 de las piezas

Las escenas de `assets/3d/` se rehicieron con formas redondeadas y la paleta de la guía visual. Abre `res://world/killawasi_revision.tscn` y pulsa **F6**.

| Tecla | Qué hace |
|---|---|
| **C** | Cambia de cámara: conjunto, cámara de juego, personajes, cadena de agua, energía |
| **N** | Día y noche |
| **D** | Escudo del domo: 100, 70, 30, 0 |
| **A** | Nivel del tanque de agua |
| **P** | Gota del procesador |
| **L** | Puerta y escalerilla de la cápsula |
| **T** | Nube de tormenta |
| **1–5** | Poses del astronauta y la vicuña |
| **F12** | Guarda una captura |

Capturas de la versión 2: [día](v2_conjunto_dia.jpg), [noche](v2_conjunto_noche.jpg), [cámara de juego](v2_camara_juego.jpg), [personajes](v2_personajes.jpg), [cadena de agua](v2_modulos_agua.jpg), [energía](v2_modulos_energia.jpg), [aterrizaje](v2_aterrizaje.jpg).

Cómo se generan y qué nombres se conservan: `assets/3d/herramientas/README.md`. Las comparativas JPG de abajo y el resto de este documento describen la versión 1.

## Versión 1

Abre `res://world/killawasi_revision.tscn` en Godot y pulsa **F6**. Pulsa **N** para alternar día y noche, **D** para recorrer los cuatro niveles visuales del domo, **A** para cambiar el nivel del tanque, **P** para reproducir la gota del procesador, **L** para abrir o cerrar el acceso y **1–5** para revisar las poses. La escena de prueba tiene seis casillas de referencia.

Para ver la nave, el Sol, la Tierra y el terreno en movimiento, abre `res://world/landing_intro.tscn` y pulsa **F6**. **Esc** o **Espacio** saltan al final. [Captura del aterrizaje](aterrizaje.png).

Para revisar un objeto separado, abre su escena en el espacio **3D** de Godot, selecciona el nodo raíz y pulsa **F** para encuadrarlo. Las escenas reutilizables se pueden arrastrar a otra escena. El polvo se aprecia durante el descenso.

La vista cercana del procesador está en `res://world/procesador_hielo_revision.tscn`. Con **F6**, pulsa **P** para reproducir la gota o **6** para alternar la vista cercana y el tamaño del 6 % en pantalla. [Comparativa con la guía](procesador_hielo_v2.jpg).

Las escenas editables están en `assets/3d/`. Los archivos `.glb` están en `assets/3d/glb/`. Las comparativas JPG usan las referencias conceptuales del equipo y renders de las escenas editables. Las imágenes de referencia llevan marca y se usan en estas comparativas de revisión. El código de generación es `assets/3d/killawasi_modelos.gd`. Se ejecutaron las tandas `first`, `rest`, el ajuste de piezas preexistentes `refine`, los ajustes de cápsula `finish_lander` y `access`, las poses `poses` y la exportación `export` con Godot 4.7.2 Standard.

## Escala y supuestos

- **[SUPUESTO]** La escala es provisional en unidades Godot. El astronauta existente mide aproximadamente dos unidades, el tanque 2,7 y el procesador 2,8 con la carga de hielo. Se usaron casillas de muestra de 5,6 × 4,2. La separación instalada del procesador y el tanque se probó en `world/moon_world.tscn`.
- **[SUPUESTO]** El procesador tiene tres rejillas traseras, cuatro apoyos cortos y una bandeja de recepción bajo el grifo. El tanque usa dos abrazaderas traseras y un frente con nivel centrado. Las vistas de la guía varían en detalles pequeños. Los tornillos, uniones ocultas y el interior del mecanismo se simplificaron.
- **[SUPUESTO]** En los demás activos se simplificaron los reversos o conexiones poco visibles en sus fichas. Los módulos nuevos miran hacia +Z. Los personajes preexistentes conservan su frente −Z y los taladros apuntan por −Z desde el agarre. Los controles en la escena de revisión son visuales.
- Las escenas de Godot conservan los shaders de la Tierra, el Sol y la vicuña. Los GLB usan materiales compatibles de aproximación para esas partes. Usa las escenas de Godot para el acabado mostrado en las comparativas y las colisiones.

## Comprobaciones

Se cargaron los 24 GLB mediante GLTFDocument en Godot. Se renderizaron las fichas y el conjunto de día y de noche en Compatibility. Se ejecutaron poses, niveles del domo y del tanque, gota del procesador, aterrizaje y saltos de la intro. Se verificaron apoyos y colisiones del procesador y el tanque por rayos. En las pruebas estáticas se alinearon las dos manos del mismo astronauta con los cuatro juegos de marcadores y se revisó el cable al montar la mochila. El agarre durante el movimiento, el cable dinámico y el ciclo de caminar con apoyo estable requieren revisión con el controlador del puesto 4. Los gestos de la vicuña son poses de pivotes y el habla de muestra es un gesto de cabeza.

La integración de acciones, tiempos de excavación, recursos, estados automáticos y recorrido del rover queda con los puestos correspondientes. La escena principal conserva el montaje del puesto 1.
