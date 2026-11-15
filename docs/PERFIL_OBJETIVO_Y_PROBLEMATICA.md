# Killawasi — Problemática, Solución Implementada, Impacto Educativo y Perfil Objetivo

> **Proyecto:** *Killawasi* (*Casa de la Luna* en kichwa)<br>
> **Equipo:** ChullaSolution (ESPOCH, Riobamba, Ecuador)<br>
> **Reto:** NASA Space Apps Challenge 2026 — *Build a Junior Astronaut Mission Trainer* (enseñar a niños de **7 a 12 años** hechos reales sobre cómo sobreviven los astronautas)<br>
> **Base documental y técnica verificada en el repositorio:** `README.md`, `docs/DISENO_JUEGO.md`, `docs/DATA_PROVENANCE.md` y la implementación actual en Godot (`core/`, `ui/`, `interaction/`, `progression/`, `data/`).

---

## 1. Definición de la Problemática (Opción B)

### Enunciado central
**Brecha de alfabetización STEM temprana y falta de comprensión científica práctica sobre cómo sobreviven los astronautas en entornos extremos (7 a 12 años).**

### Descripción detallada del problema
Entre los **7 y 12 años**, la mayoría de niñas y niños siente curiosidad por el espacio, los cohetes y los astronautas, pero suele quedar expuesta casi únicamente a dos extremos poco efectivos para su formación científica:

1. **Entretenimiento espacial desconectado de la física real:** videojuegos o relatos donde hay oxígeno ilimitado, energía infinita y peligros ficticios, reforzando la idea errónea de que vivir fuera de la Tierra es cuestión de acción sin restricciones ambientales ni soporte vital.
2. **Contenidos escolares teóricos y abstractos:** explicaciones memorísticas sobre energía solar, radiación o estados del agua, sin herramientas interactivas ni simuladores comprensibles donde el niño vea cómo una variable afecta directamente a otra.

Como consecuencia, los estudiantes no llegan a entender **por qué** las misiones espaciales requieren ingeniería sistémica, datos medidos y planificación preventiva, generando desinterés temprano o percepción de que la ciencia y la ingeniería espacial son lejanas e inaccesibles.

---

## 2. Qué se necesita saber y desarrollar para "ser astronauta" en este contexto

Dentro del marco científico y educativo de *Killawasi*, convertirse en un "astronauta junior" implica comprender y practicar **cuatro pilares reales de supervivencia lunar**, traduciendo conceptos utilizados en misiones e investigaciones de la NASA ([`DATA_PROVENANCE.md`](DATA_PROVENANCE.md)) a decisiones concretas:

### 2.1 Gestión energética dependiente del ciclo solar
- **Qué necesita comprender el niño:** La electricidad no es ilimitada; en la Luna los paneles solares solo generan energía durante la fase diurna (referencia de irradiancia solar en el Polo Sur lunar: `1,361 W/m² × 29% = 394.7 W/m²`), mientras que durante la noche la base sigue consumiendo energía (por soporte vital y calefacción nocturna).
- **Competencia desarrollada:** Instalar paneles solares en la proporción necesaria, acumular reservas mediante banco de baterías y evitar agotar la energía en la fase nocturna.

### 2.2 Búsqueda, extracción y procesamiento de agua (*ISRU*)
- **Qué necesita comprender el niño:** El agua pesa demasiado para llevarla toda desde la Tierra; en el Polo Sur lunar existen depósitos de hielo en zonas/cráteres sombreados (referencias `VIPER`, `TRIDENT`, `Apollo ALSD` y `LCROSS`, ~`5.6%` en masa). El hielo no sirve tal cual: debe recolectarse en expediciones con robot/rover y llevarse **de vuelta a la base** para procesarlo en agua líquida y sostener el sistema cerrado (referencia ISS `WRS / UPA` escalada para 4 humanos).
- **Competencia desarrollada:** Planificar expediciones al cráter cuidando la **batería del robot** y su **capacidad máxima de carga de hielo**, mejorando progresivamente las herramientas (pala, pico y taladros).

### 2.3 Soporte vital acoplado (Energía – Agua – Oxígeno)
- **Qué necesita comprender el niño:** Los humanos necesitan oxígeno y agua continuos (referencia `BVAD NASA/TP-2015-218570` y `Artemis LSH` para 4 tripulantes: `0.85 kg/persona·día` de `O₂` y recuperación/consumo de `H₂O`). El generador de oxígeno requiere **agua** y **energía** simultáneamente, y un jardín hidropónico ayuda a sostener la base una vez desbloqueado.
- **Competencia desarrollada:** Pensamiento sistémico; entender que descuidar una barra (por ejemplo, quedarse sin hielo/agua o sin energía) desencadena escasez en la siguiente (oxígeno).

### 2.4 Protección ante peligros espaciales invisibles (Radiación y Tormentas Solares)
- **Qué necesita comprender el niño:** En la Luna no existe atmósfera ni campo magnético protector; la radiación basal lunar (`9.13 μGy/h`, `LRO CRaTER-D1D2`) aumenta drásticamente durante eventos de partículas solares (`SPE` / alertas `DONKI`, con picos registrados de `3,152–61,829 μGy/h` y referencias de flujo en `pfu`). Además, con **honestidad científica**, el juego aclara que una tormenta solar real no es una "nube visible", sino partículas invisibles representadas simbólicamente para poder leerlas en pantalla.
- **Competencia desarrollada:** Cultura de prevención ante alertas tempranas (cuenta regresiva antes de la tormenta), reparación oportuna del escudo en la cápsula base, protección dentro del domo y respeto a la evidencia verificable.

---

## 3. Solución implementada en *Killawasi*

La aplicación implementa un **simulador 3D educativo bilingüe (inglés y español)** construido en Godot (`scenes/main.tscn`, `scenes/juego.tscn`) pensado para enseñar haciendo, con progresión guiada y cero fricción técnica.

### 3.1 Flujo de entrada lineal, personalización y juego compartido
- **Pantalla principal unificada con 3 slots ([`save_slots_panel.gd`](../ui/save_slots_panel.gd), [`save_manager.gd`](../progression/save_manager.gd)):** Al abrir el juego, el niño ve directamente los **3 slots de guardado** (suficientes para hermanos, uso familiar o grupos escolares en un mismo equipo), junto con acceso al **Tutorial**, **Opciones y Voz** y selector rápido de idioma **EN / ES**.
- **Configuración de nueva partida ([`new_slot_setup.gd`](../ui/new_slot_setup.gd)):** Al elegir un slot vacío, selecciona su rango de edad/dificultad (**Cadete `7–9` años** o **Ingeniero `10–12` años**) e ingresa su nombre de astronauta con vista previa 3D interactiva del personaje.
- **Tutorial inteligente en primera vez ([`main.gd`](../core/main.gd), [`intro.gd`](../ui/intro.gd), [`tutorial_steps.gd`](../ui/tutorial_steps.gd)):**
  - Si es la **primera vez** que se juega (`tutorial_seen = false`), inicia automáticamente un tutorial práctico de **18 pasos** guiado por **Timmy, la vicuña astronauta** (con texto breve y voz sintética en el idioma elegido) y pasa directo a la partida sin pantallas intermedias redundantes.
  - Si ya se completó o vio antes (`tutorial_seen = true`), una nueva partida entra directo al mundo lunar, manteniendo la opción de repetir el tutorial desde el menú principal o revisar guías dentro del juego.
  - Al seleccionar un slot ya ocupado, carga el progreso guardado (misiones, mejoras, mundo 3D, recursos y calendario) y entra directo al juego.

### 3.2 Simulación lunar comprensible y retroalimentación constante
- **5 barras vitales interdependientes en el HUD ([`live_hud.gd`](../ui/live_hud.gd)):** `Energía`, `Agua`, `Oxígeno`, `Escudo` y `Energía del Robot`.
- **Calendario lunar legible ([`mission_clock.gd`](../ui/mission_clock.gd)):** El reloj muestra únicamente **Días** durante el primer ciclo y, al cumplir cada ciclo de 30 días, suma **Meses** (`Mes 1`, `Mes 2`, etc.), ayudando a niños de primaria a seguir la duración de la misión sin ruido visual de horas/minutos.
- **Base protegida dentro del Domo:** Los módulos constructibles (`panel_solar`, `procesador_hielo`, `generador_oxigeno`, `tanque_agua`, `jardin`) se colocan únicamente dentro del perímetro seguro del domo (`placement_system.dome_inner_radius`), mientras las reparaciones del escudo se realizan desde la cápsula (`Capsula`) y el descanso/recarga del robot dentro del radio del domo.
- **Expediciones fuera de la base ([`ice_expedition.gd`](../ui/ice_expedition.gd), [`route_planner.gd`](../interaction/route_planner.gd)):** Navegación automática en malla 3D (`AStarGrid2D`) hacia `CraterHielo` y zonas descubribles (`ridge`, `basin`), respetando límites de batería, límites de carga de hielo, exposición durante tormentas y la obligatoriedad de volver a la base para procesar el hielo recolectado.

### 3.3 Progresión, expansión física de la base y divulgación científica
- **16 misiones progresivas y 12 mejoras tecnológicas en 4 ramas:** Las misiones otorgan estrellas (24 en total) que se invierten en el árbol de mejoras para ampliar límites estructurales, eficiencia energética, escudo, herramientas y soporte vital.
- **Expansión visible del Domo y cápsulas de suministro ([`juego.gd`](../core/juego.gd), [`live_game.gd`](../ui/live_game.gd), [`supply_drop.gd`](../interaction/supply_drop.gd)):**<br>
  Cuando el niño desbloquea mejoras que amplían la capacidad constructiva de la base (`panel_extra` y `jardin_lunar`), el domo crece físicamente siguiendo la fórmula `nuevo_tamaño = tamaño_actual + (tamaño_actual * 1.25)` (`3.0 -> 6.75 -> 15.1875`), ajustando también el radio interno de construcción, recarga y posición de cráteres externos. Al mismo tiempo, cae desde órbita una **cápsula de suministro con paracaídas, baliza y etiqueta del nuevo módulo** (`+1 Panel Solar` o `+1 Jardín Hidropónico`), que el jugador puede cliquear para acercar al robot, simular la recolección con barra de progreso y sumar el edificio a su inventario.
- **Colección científica con fuentes verificables ([`science_collection.gd`](../ui/science_collection.gd)):** Cada avance desbloquea cartas científicas que explican datos reales con su fuente institucional citada y botón de lectura en voz alta.
- **Recuperación segura y persistencia confiable ([`run_session.gd`](../progression/run_session.gd)):** En modo *Cadete*, si ocurre una falla crítica no hay un fin punitivo: regresa al último *checkpoint* limpio (reiniciando alertas y tormentas residuales) para analizar qué ajustar. En modo *Ingeniero*, reinicia la expedición para poner a prueba una nueva estrategia. El guardado automático por slot conserva inventario, edificios colocados, cápsulas pendientes y avances.

---

## 4. Por qué es importante educar a los niños bajo esta problemática

1. **Consolidación temprana de la autoeficacia STEM (7–12 años):**<br>
   En esta etapa escolar los niños definen si perciben la ciencia y la tecnología como algo “para ellos” o como algo “muy difícil”. Resolver problemas reales de energía, agua y escudo en formato lúdico demuestra que **pueden pensar como ingenieros**.
2. **Aprendizaje activo por experimentación (aprender probando):**<br>
   Ver caer la producción solar de noche, quedarse sin agua por no explorar el cráter o reparar el escudo tras una alerta solar construye intuición física real que supera ampliamente la memorización pasiva.
3. **Alfabetización en datos reales y pensamiento crítico:**<br>
   Integrar tarjetas científicas con fuentes oficiales (`LRO CRaTER`, `DONKI`, `BVAD`, `WRS`, `VIPER`, `LCROSS`) y aclarar explícitamente cuándo un elemento es un símbolo didáctico enseña desde la infancia a **contrastar juego vs. realidad científica**.
4. **Identidad y acceso bilingüe inclusivo:**<br>
   Elegir una vicuña astronauta (**Timmy**) y un título en kichwa (**Killawasi**) rompe la idea de que la ciencia espacial pertenece solo a otros idiomas o regiones, conectando cultura andina con exploración espacial moderna tanto en español como en inglés.
5. **Puente entre el espacio y la sostenibilidad terrestre:**<br>
   Comprender lo costoso que es generar electricidad limpia, reciclar agua y proteger un entorno cerrado en la Luna fortalece la conciencia ecológica y energética del niño en la Tierra.

---

## 5. Consecuencias de NO educar a los niños frente a esta problemática

1. **Deserción temprana de vocaciones STEM:**<br>
   Sin experiencias prácticas y amables entre los 7 y 12 años, la física, las matemáticas y la ingeniería suelen percibirse como materias áridas en la secundaria, reduciendo futuros estudiantes en áreas científicas, tecnológicas y aeroespaciales.
2. **Persistencia de mitos científicos y desinformación:**<br>
   Los niños crecen asumiendo ideas falsas sobre el espacio (aire libre, ausencia de riesgo por radiación solar o recursos infinitos), debilitando su criterio científico frente a noticias o contenidos pseudocientíficos.
3. **Dificultad para comprender sistemas complejos e interdependientes:**<br>
   No entrenar el pensamiento causa–efecto entre energía, agua y protección ambiental limita la capacidad futura para tomar decisiones informadas sobre escasez hídrica, transición energética y gestión de riesgos en su propia comunidad.
4. **Ampliación de la brecha de equidad educativa:**<br>
   Si no existen simuladores educativos livianos, gratuitos/locales, en español e inglés y compartibles en computadores comunes de escuela o casa, el acceso a formación espacial práctica queda reservado a pocos contextos privilegiados.

---

## 6. Perfil Objetivo de los Niños (*Target User Persona*)

### 6.1 Perfil general del usuario objetivo
- **Rango de edad:** **7 a 12 años** (Educación Básica / Primaria media y superior).
- **Idioma:** Hispanohablantes o bilingües (**español / inglés**), con soporte completo de texto y voz sintética en ambos idiomas.
- **Contexto de uso:** Hogar (PC compartida entre hermanos), aulas de Ciencias Naturales/Tecnología, clubes escolares de astronomía o robótica, y ferias científicas. El sistema de **3 slots independientes** permite que hasta tres niños guarden su propio avance en una misma máquina.
- **Conocimientos previos necesarios:** Lectura básica y nociones cotidianas de sol, agua, aire y batería. **No requiere** conocimientos previos de física, programación ni videojuegos complejos de estrategia.
- **Motivaciones principales:** Curiosidad por la Luna y los robots, construir bases espaciales visibles tipo maqueta, acompañar a un personaje simpático (**Timmy la vicuña**) y ver recompensas tangibles (domo más grande y cápsulas que caen con nuevos módulos).
- **Barreras y necesidades de diseño cubiertas:** Baja tolerancia a textos largos sin audio, frustración por controles de cámara complejos y abandono ante derrotas definitivas injustas en niños menores.

### 6.2 Segmentación en los dos subperfiles del juego

| Criterio | Subperfil 1: **Explorador Cadete** (`7–9` años) | Subperfil 2: **Pequeño Ingeniero** (`10–12` años) |
|---|---|---|
| **Equivalencia en el juego** | Modo **Cadete** (`age_group = "7_9"`) | Modo **Ingeniero** (`age_group = "10_12"`) |
| **Nivel escolar aproximado** | 2.º a 4.º de primaria / básica elemental-media | 5.º a 7.º de primaria / pre-secundaria |
| **Pregunta motivadora** | *“¿Cómo vive un astronauta en la Luna y qué hace cada máquina?”* | *“¿Cómo optimizo energía, agua, oxígeno y escudo para superar tormentas más duras?”* |
| **Forma de aprendizaje predominante** | Visual y auditivo: tutorial de 18 pasos con Timmy, voz narrada, botones e íconos claros, textos cortos | Analítico y estratégico: lectura de alertas, cartas científicas con fuentes NASA y árbol de mejoras |
| **Manejo del error y dificultad** | Costos más bajos; ante falla crítica **vuelve al último checkpoint** para corregir sin perder su base | Mayor consumo y daño; si falla **reinicia la partida**, incentivando planeación preventiva real |
| **Interacción típica dentro de *Killawasi*** | Mueve al robot al cráter, construye sus primeros módulos dentro del domo, disfruta la caída y recogida de cápsulas | Equilibra las 5 barras, gestiona la noche lunar con baterías, anticipa tormentas y busca completar las 16 misiones y 12 mejoras |
| **Acompañamiento adulto/docente** | Opcional en la primera sesión para elegir idioma/slot o comentar las fichas científicas | Uso autónomo tanto en casa como en retos cronometrados o proyectos escolares STEM |

---

## 7. Matriz de trazabilidad: Problemática → Necesidad → Solución en el juego

| Qué exige la problemática (Opción B) | Necesidad educativa del niño | Cómo lo resuelve *Killawasi* en código/diseño |
|---|---|---|
| Superar barreras técnicas y lectoras al iniciar | Entrada clara, en su idioma y sin perder progreso propio | Pantalla inicial de **3 slots**, selector **EN/ES**, configuración de edad/nombre y tutorial en primera vez (`main.gd`, `save_slots_panel.gd`, `new_slot_setup.gd`) |
| Diferenciar madurez cognitiva (`7–9` vs `10–12`) | Reto ajustado sin aburrir ni frustrar | Dos modos con parámetros y recuperación diferenciada: **Cadete** (checkpoint) vs **Ingeniero** (reinicio) |
| Comprender sistemas físicos interdependientes | Ver en tiempo real la relación energía–hielo–agua–oxígeno–escudo | 5 barras acopladas, ciclo solar día/noche, extracción de hielo fuera del domo y procesamiento obligatorio en base (`juego.gd`, `ice_expedition.gd`) |
| Conocer peligros reales no intuitivos (radiación) | Identificar tormentas solares como eventos medibles, no fantasía | Alertas previas con cuenta regresiva, escudo reparable en la cápsula y aclaración científica de la nube simbólica (`juego.gd`, `DISENO_JUEGO.md`) |
| Fomentar cultura de evidencia científica | Conectar el juego con ciencia verificable | 16 misiones, 12 mejoras y tarjetas con datos y fuentes NASA citadas (`science_collection.gd`, `DATA_PROVENANCE.md`) |
| Mantener motivación por progreso tangible | Recompensa visual comprensible al planificar e investigar | Expansión del domo `+(tamaño actual) * 1.25` y caída de cápsulas `SupplyDrop` recolectables con `+1` edificio desbloqueado (`supply_drop.gd`, `live_game.gd`) |
