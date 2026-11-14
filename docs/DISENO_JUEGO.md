# Diseño del juego · Inti Killa

Estado: **sábado 14 de noviembre, 11:30.** Lo decidió el líder (puesto 1) con el equipo. Si algo de aquí cambia, se cambia en este archivo por Pull Request, no en el chat.
Todos los números de este documento son **valores de prueba en unidades de juego**. No son datos de NASA. Se ajustan jugando.

## Lo ya decidido

| Tema | Decisión |
|---|---|
| Nombre | **Inti Killa**: «Sol» y «Luna» en kichwa |
| Guía | **Vicuña astronauta**, personaje original nuestro |
| Estilo | **Low-poly** con luces suaves, como una maqueta (ver [`ESTILO_VISUAL.md`](ESTILO_VISUAL.md)) |
| Personaje que juega | **El astronauta**: aterriza y se mueve por la Luna. La Vicuña es la guía que lo acompaña |
| Modos | **Cadete 7 a 10 años** e **Ingeniero 11 a 12 años**, con el mismo núcleo de simulación |
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

Valores de prueba: primera tormenta a los 3 minutos de juego, luego una cada 4. Cada golpe quita 30 de 100 de Escudo. Reparar cuesta 20 de energía y 5 segundos.

**Honestidad científica.** Una tormenta solar real no es lluvia ni nube que se vea: son partículas. La nube es un **símbolo** y el juego lo dice. Las tormentas se basan en eventos reales (RadLab y DONKI), cada una con su ficha de «Datos reales», fecha, fuente y unidades.

### Viaje por hielo y herramientas

El viaje cuesta Vida y tiempo. Mejor herramienta significa más hielo por viaje y menos Vida perdida.

| Nivel | Herramienta | Hielo por viaje | Costo de Vida por viaje |
|---|---|---|---|
| 1 | Pala | 2 | alto |
| 2 | Pico | 4 | alto |
| 3 | Taladro manual | 7 | medio |
| 4 | Taladro con mochila | 10 | bajo |

El jugador empieza con la pala. Las herramientas se mejoran con estrellas, en la rama **Herramientas** del árbol.

## Misiones, estrellas y árbol

- **Misión fácil: 1 estrella. Misión difícil: 2 estrellas.** Equivale a «una difícil vale dos fáciles».
- Cada mejora del árbol cuesta **2, 4 o 6 estrellas**.
- Ejemplos de misión fácil: «Instala un panel solar», «Trae 4 de hielo».
- Ejemplo de misión difícil: «Aguanta una tormenta sin que el Escudo baje de 30».

**Cuatro ramas del árbol:**

| Rama | Qué mejora |
|---|---|
| Energía | Más paneles, baterías, más producción |
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
