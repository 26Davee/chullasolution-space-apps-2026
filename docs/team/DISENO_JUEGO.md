# Diseño del juego · Killawasi

Estado: **sábado 14 de noviembre, 11:30.** Lo decidió el líder (puesto 1) con el equipo. Si algo de aquí cambia, se cambia en este archivo por Pull Request, no en el chat.
Todos los números de este documento son **valores de prueba en unidades de juego**. No son datos de NASA. Se ajustan jugando.

## Lo ya decidido

| Tema | Decisión |
|---|---|
| Nombre | **Killawasi**: «killa» (luna) y «wasi» (casa) en kichwa, «Casa de la Luna». Pendiente confirmar con la persona que habla kichwa |
| Guía | **Vicuña astronauta**, personaje original nuestro |
| Estilo | **Low-poly** con luces suaves, como una maqueta (ver [`ESTILO_VISUAL.md`](ESTILO_VISUAL.md)) |
| Personaje que juega | **El astronauta**: aterriza y se mueve por la Luna. La Vicuña es la guía que lo acompaña |
| Modos | **Cadete 7 a 10 años** e **Ingeniero 11 a 12 años**, con el mismo núcleo de simulación. Todas las piezas existen en los dos modos: en Cadete cuestan menos y en Ingeniero más |
| Cámara | Como Clash of Clans: inclinada y fija, se arrastra y se acerca, no gira |
| Voz de la guía | Primero texto para leer. Después, voz sintética si hay tiempo |
| Se construye primero | **Cadete**. Ingeniero después |

## Flujo del juego

1. **Primera vez que se abre:** tutorial de la Vicuña, de 60 a 90 segundos, igual para los dos modos.
2. **Menú de modo:** el niño elige Cadete o Ingeniero. Las veces siguientes el tutorial se puede saltar.
3. **Modo Cadete:** la nave aterriza, aparece la Vicuña, sale el primer globito de bienvenida y empieza el juego.

El tutorial es una **escena dentro del juego**, no un video grabado. Así se traduce a inglés y español, se puede saltar y no pesa.

## El bucle de Cadete

El niño maneja tres barras: **Energía**, **Vida** y **Escudo**. Todo se mueve con estas reglas:

- **Energía.** La producen los paneles solares. No se recolecta. De noche los paneles no producen.
- **Hielo.** Es **el único recurso que se recolecta**. El astronauta camina a un cráter, lo recoge y vuelve.
- **Agua y oxígeno.** En la base, el procesador convierte el hielo en agua. Con agua y energía se produce oxígeno.
- **Vida.** Es la salud del astronauta. Baja en cada viaje por hielo, por la radiación y el oxígeno que gasta fuera del refugio.
- **Escudo.** Protege la base de la radiación. Baja cuando llega una tormenta y se repara con energía.

### La tormenta y el escudo

1. Cada cierto tiempo llega una **nube de radiación**. Antes aparece un aviso con cuenta atrás.
2. La nube cae sobre el domo y baja la barra del Escudo.
3. El niño **repara el escudo** tocando el domo. Cuesta energía y unos segundos.
4. Si el Escudo llega a cero, la tripulación sufre un daño leve. Nunca hay pantalla de fracaso: el reporte explica qué pasó.

Valores de prueba:

| | Cadete | Ingeniero |
|---|---|---|
| Primera tormenta | a los 3 min de juego | a los 3 min de juego |
| Frecuencia | cada 4 min | cada 4 min |
| Golpe al Escudo | −30 de 100 | −40 de 100 |
| Reparar | 20 de energía y 5 s | 30 de energía y 8 s |

**Datos de las tormentas.** Hasta que Anahi entregue los eventos reales (RadLab, DONKI) con fecha, fuente y unidades, el juego usa **datos ficticios** y lo dice en pantalla. Cuando lleguen, se reemplaza el archivo de datos en `data/nasa/`; el juego no cambia.

**Honestidad científica.** Una tormenta solar real no es lluvia ni nube que se vea: son partículas. La nube es un **símbolo** y el juego lo dice. Las tormentas se basan en eventos reales (RadLab y DONKI), cada una con su ficha de «Datos reales», fecha, fuente y unidades.

### Viaje por hielo y herramientas

El viaje cuesta Vida y tiempo. Mejor herramienta significa más hielo por viaje y menos Vida perdida.

| Herramienta | Cómo se consigue | Hielo por viaje | Excavar | Viaje total | Hielo por minuto | Vida perdida Cadete | Vida perdida Ingeniero | Vida por cada hielo (Cadete) |
|---|---|---|---|---|---|---|---|---|
| 1. Pala | al empezar | 2 | 20 s | 60 s | 2,0 | −10 | −15 | 5,0 |
| 2. Pico | rama Herramientas, 2★ | 4 | 14 s | 54 s | 4,4 | −9 | −14 | 2,3 |
| 3. Taladro manual | rama Herramientas, 4★ | 7 | 10 s | 50 s | 8,4 | −6 | −9 | 0,9 |
| 4. Taladro con mochila | rama Herramientas, 6★ | 10 | 6 s | 46 s | 13,0 | −3 | −5 | 0,3 |

Cada herramienta es más eficiente que la anterior: más hielo por viaje, menos tiempo excavando y menos Vida perdida. El viaje total son 40 s caminando más el tiempo de excavar. Durante la nube la Vida perdida se multiplica por 1,5.

Los números de Vida son una **propuesta** para afinar con Anahi. Propuesta también: la Vida sube descansando dentro del domo con oxígeno.

## Con qué aparece el astronauta y niveles de la base

El astronauta aterriza con: traje (Vida 100), **pala**, la **cápsula** como base (proyecta el escudo, Escudo 100), **1 panel solar gratis** y reservas de Energía 60, Agua 20, Oxígeno 60 y Hielo 0.

La base sube de nivel con las **estrellas ganadas en total** (esas no se gastan; las del árbol sí). Cada nivel desbloquea piezas y cupos:

| Nivel | Nombre | Estrellas ganadas | Desbloquea | Cupos |
|---|---|---|---|---|
| 1 | Aterrizaje | 0 | Panel solar, procesador de hielo, generador de oxígeno | 2 paneles, 1 procesador, 1 generador |
| 2 | Campamento | 3 | Tanque de agua | 3 paneles, 1 tanque |
| 3 | Base | 6 | Segundo procesador de hielo | 4 paneles, 2 procesadores |
| 4 | Estación | 10 | Reciclador de agua y segundo tanque | 5 paneles, 2 tanques, 1 reciclador |
| 5 | Colonia (si sobra tiempo) | 14 | Más cupos y una base más grande | 6 paneles |

El agua máxima es 60 y cada tanque suma 50. Detalle completo, con tasas, costos y un ejemplo de 10 minutos, en el documento «Killawasi · Reglas del juego, costos y estructuras».

## Piezas y costos

**Todas las piezas se pueden construir en los dos modos.** Lo que cambia es el costo: en Cadete cuestan menos y en Ingeniero cuestan una vez y media más. Valores de prueba en unidades de juego (no son datos de NASA):

| Pieza | Qué hace | Desde el nivel | Cadete (energía) | Ingeniero (energía) |
|---|---|---|---|---|
| Panel solar | Da energía de día (+0,6 por s). De noche no produce | 1 | 15 (el primero es gratis) | 23 (el primero es gratis) |
| Procesador de hielo | Convierte 1 hielo en 10 de agua en 5 s | 1 | 25 | 38 |
| Generador de oxígeno | Usa agua y energía para hacer aire (+0,45 por s) | 1 | 30 | 45 |
| Tanque de agua | Agua máxima +50 | 2 | 20 | 30 |
| Reciclador de agua | El generador gasta 30 % menos agua | 4 | 35 | 53 |
| Jardín | Vida +0,2 por s extra (rama Vida, 6★) | árbol | 40 | 60 |
| Reparar el escudo (acción) | Devuelve +50 de Escudo en Cadete, +40 en Ingeniero | 1 | 20 + 5 s | 30 + 8 s |

Estos números van en una tabla de datos por modo, no escritos dentro del código.

## Misiones, estrellas y árbol

- **Misión fácil: 1 estrella. Misión difícil: 2 estrellas.** Equivale a «una difícil vale dos fáciles».
- Cada mejora del árbol cuesta **2, 4 o 6 estrellas**.
- Ejemplos de misión fácil: «Instala un panel solar», «Trae 4 de hielo».
- Ejemplo de misión difícil: «Aguanta una tormenta sin que el Escudo baje de 30».

**Cuatro ramas del árbol:**

| Rama | Qué mejora |
|---|---|
| Energía | Panel eficiente, batería y paneles de alto rendimiento (los paneles nuevos los da el nivel de la base) |
| Vida | Procesar hielo más rápido, oxígeno, jardín |
| Escudo | Más resistencia y reparación más barata |
| **Herramientas** | Pala, pico, taladro y mochila |

Cada mejora desbloqueada entrega una **carta de dato** con una afirmación verdadera y su fuente. Si no se puede citar la fuente, la carta no entra.

## Cámara

Estilo Clash of Clans: ángulo y orientación **fijos** (inclinada unos 45°), **sin rotación**. Se arrastra para mover la vista y se acerca con la rueda del ratón o con pellizco. El astronauta camina con un clic. La cámara puede seguirlo y dejarlo de seguir si el niño arrastra.

## Tutorial de la Vicuña

Sirve para los dos modos. Enseña, con globitos cortos y señalando cada cosa en pantalla:

1. Quién es la Vicuña y qué hace el astronauta en la Luna.
2. Cómo mover la cámara y cómo caminar.
3. Las tres barras: Energía, Vida y Escudo.
4. Cómo colocar un panel y de dónde sale la energía.
5. Cómo traer hielo y procesarlo en agua y oxígeno.
6. Qué es la nube de radiación y cómo reparar el escudo.

Todos los textos van como **claves de traducción** (inglés y español), nunca escritos dentro del código.

## Voz de la Vicuña

- **Ahora:** texto para leer, con un sonido corto de animal. Sin grabaciones.
- **Si hay tiempo:** voz sintética con la función de texto a voz de Godot (`DisplayServer.tts_speak`), que usa la voz del sistema o del navegador. Hay que probarla en la versión web, en los computadores donde se va a jugar.
- **Regla de NASA:** no se usa voz ni imagen de menores de 18 años.

## Qué hace cada puesto

| Puesto | Persona | Lo suyo en este diseño |
|---|---|---|
| 1 | Ángel | Flujo de escenas (arranque, tutorial, menú, juego), guardar «tutorial visto», nombre del proyecto, versión web |
| 2 | Anahi | Simulación: energía, hielo, agua, oxígeno, Vida, Escudo, tormenta, costos del viaje, datos reales |
| 3 | Carlos Valladares | Astronauta, Vicuña, cápsula, domo, panel, procesador de hielo, cráter, nube de radiación, terreno low-poly |
| 4 | Nicolás Ladino | Cámara estilo Clash of Clans, caminar con clic, recoger hielo, colocar piezas, sonidos |
| 5 | Gael | Misiones fáciles y difíciles, estrellas, árbol con sus cuatro ramas, cartas de dato |
| 6 | Andrea | Tutorial y globitos de la Vicuña, menú de modo, barras y avisos, textos en inglés y español, voz |

Las claves nuevas que se pasan entre puestos (por ejemplo `hielo`, `escudo`, `herramienta_nivel`, `estrellas`) se agregan a `docs/CONTRATOS.md` con el acuerdo de los puestos 2 y 5.

## Qué se hace primero

| Hora | Meta |
|---|---|
| Sáb 16:00 | **Versión 1 en línea:** aterrizaje, Vicuña con globito de bienvenida, un panel, tormenta con escudo reparable, un viaje por hielo con la pala y estrellas |
| Sáb noche | Capa 1 completa en Cadete: procesar hielo a agua y oxígeno, día y noche, panel de «Datos reales» |
| Dom mañana | Árbol con Herramientas, tutorial completo y menú de modo |
| Dom 12:00 | Se congela el juego: solo se arreglan errores |
| Si sobra tiempo | Modo Ingeniero, voz sintética, informe para el aula |

## Lo que no entra

Cuentas, anuncios, compras, rachas diarias, datos personales, y cualquier voz o imagen de menores de 18 años.

## Bloque 2: qué hace cada puesto hasta la versión 1 (sáb 16:00)

Primero se sube al repositorio lo hecho en el bloque 1. Después:

| Puesto | Persona | Entrega | Hora tope |
|---|---|---|---|
| 3 | Carlos Valladares | Astronauta y cápsula (`.glb` en `assets/3d/`, 1 unidad = 1 m, pivote en los pies, animaciones quieto y caminar). Luego terreno con casillas, cráter de hielo, panel solar y pala | Astronauta 13:00. Resto 15:00 |
| 4 | Nicolás Ladino | Caminar con clic y cámara siguiendo; recoger hielo; colocar piezas en casillas; tocar la base para reparar (con un cubo hasta que llegue el astronauta) | Caminar 14:00. Resto 15:30 |
| 2 | Anahi | Tablas `data/balance/cadete.json` e `ingeniero.json`; simulación; calendario de nubes; un conjunto de datos de NASA con su ficha | Tablas 13:30. Simulación 15:00. Ficha 16:00 |
| 5 | Gael | 13 misiones como datos, estrellas, nivel de la base (0, 3, 6, 10), árbol de 12 mejoras | Datos 14:00. Lógica 15:30 |
| 6 | Andrea | Seis barras, estrellas, nivel y misión en pantalla; aviso de la nube; textos de bienvenida y tutorial (pasos 1 a 3) ES/EN | HUD 14:30. Tutorial 15:30 |
| 1 | Ángel | Fusionar PR #1 y #2, `docs/CONTRATOS.md`, escenas título → tutorial → menú → juego, integración | Contratos 13:00. Integración 15:30. Versión 1 16:00 |

Sincronía: 13:00 contratos y astronauta, 15:00 todos con su Pull Request abierto, 15:30 integración, 16:00 versión 1. Cada puesto usa un sustituto simple hasta que llegue lo del otro.
