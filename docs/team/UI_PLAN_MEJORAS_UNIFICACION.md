# Plan de interfaz sobre la rama unificada

Fecha: 15 de noviembre de 2026. Rama: **unificacion_v1_proyect**, base revisada **fde4510**. Comparación con **origin/p6/inicio-timmy**.

Este documento conserva el diagnóstico previo a implementar. Después, la integrante autorizó la corrección en esta rama y un reparto inicial editable de suministros. El resultado y la validación están documentados en [INTEGRACION_PARTIDA.md](INTEGRACION_PARTIDA.md). Las tablas siguientes describen los fallos encontrados antes de implementar.

## Decisiones vigentes

- La integrante confirmó conservar el **robot y las nuevas reglas** de la integración.
- Mantener Energía de la base, Agua, Oxígeno de la tripulación y Escudo en una fila; la batería del robot es un estado distinto.
- Conservar edades 7–9 Cadete y 10–12 Ingeniero y las voces Zira/Sabina.
- Conservar el estilo de Misiones y Upgrades. Ajustar sus datos, tamaños y mensajes sin rediseñar su identidad visual.
- Determinadas misiones entregarán módulos como suministros. La lista de misión, módulo y cantidad debe venir de P5 y el estado de inventario del sistema de juego.
- La victoria ocurre al completar **todas las misiones**: 16 en el JSON actual. El tiempo o un cambio de día no terminan por sí solos la campaña.
- Usar iconos vectoriales coherentes con la interfaz, reemplazando los símbolos que se renderizan como emojis. Etiquetas breves, voz y ayudas acompañan los iconos.

## Qué se conserva y qué ya se integró

El tutorial, menú de inicio, transiciones, traducciones, voces y componentes de Misiones/Upgrades de P6 siguen en la rama. El modelo por defecto ahora es robot_humanoide.tscn, hay cuatro recursos principales y el tutorial tiene 19 pasos.

La partida real se abre en scenes/juego.tscn. core/juego.gd construye otra capa de interfaz y conecta el mundo 3D, movimiento, colocación, GameState y progresión. Por eso F5 ya no termina en la imagen provisional que se usaba durante el trabajo de P6.

Ya existen colocación 3D con holograma, acciones de hielo/procesamiento/reparación, misión activa, avisos de tormenta, compras y persistencia de estrellas, misiones, mejoras y cartas. Parte de las 14 funciones está empezada: no corresponde reconstruirla por separado.

## Problemas confirmados que requieren corrección

| Prioridad | Hallazgo | Evidencia de la revisión | Corrección propuesta y responsables |
|---|---|---|---|
| Urgente | Misión activa sin título ni objetivo | La captura muestra “Active Mission ·” y descripción vacía. El render pide titulo/descripcion/recompensa_estrellas, pero el JSON y MissionManager entregan mision/objetivo/puntos. | Normalizar los datos en el adaptador y renderizar objetivo/progreso correctos. P6 con conexión de P1/P5. |
| Urgente | Volver al menú reinicia la partida | core/main.gd conecta salir_al_menu a mostrar_titulo; mostrar_titulo llama a GameState.reiniciar y destruye la escena anterior. | Reutilizar el menú de inicio, pausar y conservar la sesión para Reanudar. P1 conecta el flujo; P6 presenta los estados. |
| Urgente | El checkpoint del Cadete no se restaura | La ventana dice checkpoint, pero su botón llama iniciar_partida, que reinicia recursos. SaveManager no contiene posición, estructuras o recursos de un checkpoint. | Guardar/restaurar una instantánea completa y reflejar su resultado. P1/P2/P4/P5; ventana y mensajes P6. |
| Urgente | Saldo de estrellas de pantalla y compra no coincide | Prueba aislada: compra correcta con saldo mostrado 10 y saldo autorizado 9. TechTree emite estrellas_actualizadas, pero el estado usado por el HUD no se actualiza con esa resta. | Una única fuente de estrellas disponibles para HUD, árbol y compras. P1/P5; P6 consume el valor. |
| Urgente | Doble avance del tiempo en el modo de simulación de respaldo | GameState._process suma delta sin simulación; el fallback de core/juego.gd también. Diagnóstico aislado: delta 1 por ambos productores da 2 segundos de juego. | Un solo dueño del reloj y de la evaluación de simulación. P1/P2. La UI únicamente lo lee. |
| Urgente | El texto de derrota contradice el dato comprobado | El tutorial dice batería del robot u oxígeno; GameBridge._check_failure comprueba energía de la base u oxígeno. La batería a cero detiene el movimiento en el fallback. | P1/P2 deben fijar un contrato inequívoco. P6 alinea textos y ventanas con ese contrato; se conserva el robot y no se vuelve a Vida. |
| Alta | Aviso de colocación tapa controles | En la captura, el banner centrado en y=184 invade la misión y la barra de cámara/idioma/audio. | Zonas reservadas para HUD, misión, acciones y avisos. Un aviso no comparte espacio con otro control. P6 con host P1. |
| Alta | Se duplican accesos y cambia la navegación aprobada | En la partida hay un botón Base menu con texto y ocho botones inferiores permanentes. | Recuperar una entrada clara por icono de menú; acciones contextuales cuando se necesiten. P6/P1/P4. |
| Alta | Ventanas no respetan el tamaño de sus componentes | Upgrades recibe un contenedor más pequeño que el usado en el tutorial; títulos, nodos y etiquetas quedan demasiado juntos. | Ajustar la ventana y sus márgenes al contenido o hacerlo adaptable, conservando el diseño del árbol. P6/P1. |
| Alta | Batería del robot rebasa su tarjeta | Medición en la prueba: final de la barra a 55 px en una tarjeta de 54 px. | Fijar el tamaño después de aplicar el tema y validar límites. P6. |
| Alta | Las cartas recibidas no aparecen en Science | La señal lleva carta_nasa, pero los manejadores de UI descartan _carta. Science crea la demostración de cuatro ejemplos. | Conectar cartas desbloqueadas y colección real, con narración e historial. P6/P5/P2. |
| Alta | Opciones distintas entre tutorial y partida | En juego solo hay activar/probar voz y volver; faltan los controles completos de volumen, velocidad y elección de voz del inicio. | Compartir el mismo panel y conservar preferencias entre escenas. P6/P1. |
| Alta | Reloj y estados útiles pierden claridad | El HUD nuevo muestra día/mes/año sin hora. Hay estimaciones pequeñas y emojis de tripulación mezclados con iconos propios. | Volver legible la información necesaria, mantener hora si forma parte del acuerdo del equipo y mover detalle secundario a ayudas. Las conversiones las valida P2. P6/P2. |
| Alta | Textos de eventos enseñan identificadores internos | El toast de misión busca missions.<id>.titulo, mientras las traducciones usan misiones.<id>.titulo. | Normalizar claves y usar datos localizados. Ningún id técnico visible al niño. P6/P1/P5. |

### Otros riesgos concretos que deben entrar en las pruebas

- Las ventanas no tienen el mismo control de foco y cierre que el tutorial; cámara, viaje o tiempo pueden continuar detrás. El fallback se detiene con una ventana, pero GameState sigue avanzando su reloj.
- Reiniciar recursos no basta si quedan estructuras 3D colocadas, una acción en curso o eventos de la misión anterior.
- Saltar el tutorial asigna Cadete cuando no hay edad. Debe conservar la elección real del perfil y ofrecer un recorrido claro para quien entra por primera vez.
- El guardado actual conserva progresión, no una partida completa. No rotularlo como checkpoint o reanudación completa hasta que guarde lo necesario.
- Las fuentes de las cartas del catálogo necesitan la revisión de P2 y enlaces verificables; tener texto en fuente no sustituye la verificación científica.

## Revisión de los 14 puntos

| # | Función | Estado real | Trabajo que falta |
|---|---|---|---|
| 1 | Ayuda de Timmy durante la partida | Pendiente | Acceso persistente y discreto; objetivo actual, “¿Qué hago ahora?”, consejo contextual y repetir voz. Usar el alias y respetar silencio/idioma. |
| 2 | Mensajes del Centro de Control | Parcial | Hay alertas de tormenta. Falta centro de mensajes, leído/no leído, historial y lectura con Timmy. Una cola debe dar prioridad a peligros. |
| 3 | Seguimiento de misión | Existe, con fallo de datos | Corregir campos vacíos; mostrar objetivo breve y progreso real de los triggers; enlazar con la lista existente. |
| 4 | Celebración de misión completada | Parcial | Actualmente es un toast. Mostrar nombre, estrellas, carta y suministros reales, siguiente objetivo y protección frente a eventos duplicados. |
| 5 | Recepción de suministros | Pendiente de contrato y UI | No hay campos de suministros en missions.json. P5 define misión/módulo/cantidad/id de entrega; P6 muestra recepción y acceso a Construir. |
| 6 | Inventario y colocación de módulos | Colocación real integrada; inventario pendiente | Ya se colocan módulos 3D. Faltan cantidades recibidas/disponibles y consumo de una unidad al colocar. Diferenciar existencias de cupos de construcción. El tanque de agua no está en el catálogo construible actual. |
| 7 | Cartas científicas reales | Progreso guardado, UI de ejemplo | Consultar ids desbloqueados, obtener contenido real y fuentes, narrar al recibir y consultar en Science. Reutilizar el tablero y sus tachuelas. |
| 8 | Alertas de recursos y peligros | Parcial | Hay tormenta y batería. Añadir energía base, agua, oxígeno y escudo bajos, día/noche, acciones recomendadas y umbrales acordados con P2. Evitar avisos repetidos. |
| 9 | Respuesta visual de acciones | Parcial | Hay toasts y holograma. Falta estado claro de viaje, carga, procesamiento y reparación; duración/progreso cuando el sistema lo proporcione; motivo de bloqueo y cancelación. |
| 10 | Confirmaciones de mejoras | Compra integrada; mensajes incompletos | Conservar árbol. Mostrar coste, saldo autorizado, prerrequisito que falta, rechazo concreto y éxito. No sumar o descontar dos veces desde la UI. |
| 11 | Agotamiento y recuperación, sin Vida | Inconsistente | Alinear recurso que provoca fallo. Cadete restaura checkpoint; Ingeniero reinicia la expedición completa, incluidos inventario y objetos colocados, preservando perfil/idioma/voz. |
| 12 | Guardado, pausa y reanudación | Guardado parcial; regreso reinicia | Unificar menú y sesión; detener reloj, consumos y controles al pausar. Confirmar guardado solo tras resultado correcto y restaurar una partida completa. |
| 13 | Final del juego | Pendiente | Cuando estén completados todos los ids de misión válidos: una sola celebración, resumen y acceso a colección/menú/nueva expedición. No usar “no hay misión activa” como única prueba de victoria. |
| 14 | Ayuda y estados especiales | Parcial | Ayuda real de movimiento/colocación/cámara, inventario vacío, carga, error de guardado, datos no disponibles y recuperación clara sin mostrar errores técnicos al niño. |

## Diseño visual y navegación a conservar

- Mantener el tema espacial, las imágenes existentes y los modelos del equipo.
- Menú de icono reconocible en una zona estable; no repetir las mismas siete u ocho entradas en distintos lugares permanentes.
- HUD: cuatro recursos juntos; batería del robot claramente separada de la reserva de la base. Explicar que el oxígeno es para la tripulación.
- Misión actual pequeña y legible, con una acción siguiente concreta.
- Timmy en una zona reservada; globo solo al pedir ayuda o al llegar un aviso necesario.
- Centro de mensajes y recompensas compartido: mostrar un mensaje prioritario a la vez, conservar los demás en historial y permitir repetir voz.
- Botones principales amplios; etiquetas cortas, iconos y ayudas. Un icono no debe ser la única forma de entender una acción.
- Sustituir emojis de personas, rayos o herramientas usados como interfaz por el repertorio vectorial común de ui_icon.gd. Conservar símbolos de texto solo cuando no funcionen como un botón o indicador ambiguo.
- El aviso de colocar una pieza aparece en su propia zona, sin tapar misión, cámara ni botones.
- La tienda de construcción real recupera tarjetas visuales de módulos, con cantidad, coste y disponibilidad, aprovechando las ilustraciones ya creadas o vistas 3D existentes.
- Misiones y Upgrades conservan su identidad. Se corrigen tamaño, textos, datos y estados.

## Plan de acción por fases

### Fase 0 — Alinear integración y reglas que afectan a la interfaz

**Objetivo:** que la UI no enseñe un estado o resultado distinto del juego.

1. Corregir el contrato de misión y las claves de traducción.
2. Acordar el recurso que provoca fallo; separar batería del robot, energía de la base y oxígeno.
3. Corregir reloj duplicado y saldo de estrellas disponible.
4. Definir los datos de suministros, la identidad de entrega y el inventario autorizado.
5. Definir instantánea de checkpoint/partida: recursos, objetos/posiciones, batería, herramientas, misiones y triggers, mejoras, inventario, tiempo y estado de acciones.
6. Confirmar evento de campaña completada o una consulta fiable de todos los ids completados.

**Responsables:** P1/P2/P4/P5 en sus módulos; P6 adapta mensajes y consumidores. Se puede avanzar el diseño visual en paralelo con datos de prueba identificados como tales.

**Se acepta cuando:** un mismo evento/estado tiene el mismo significado para juego, HUD, misión, cartera y guardado.

### Fase 1 — Recuperar claridad visual y navegación

1. Extraer la presentación de core/juego.gd hacia un overlay reutilizable de ui/, dejando allí las conexiones y acciones del juego.
2. Unificar menú, opciones, iconos y foco de teclado.
3. Distribuir HUD, misión, mensajes de Timmy, progreso y construcción en zonas sin colisiones.
4. Corregir barra de batería, textos cortados, tamaños de ventanas y reloj.
5. Recuperar presentación visual de módulos y evitar barra inferior llena de texto.

**Responsable:** P6; P1 conecta la escena nueva al host real. No cambiar movimiento, cámara ni modelos.

**Se acepta cuando:** el niño identifica su recurso crítico, objetivo y acceso a las acciones, y ninguna ventana o etiqueta invade otra.

### Fase 2 — Timmy, misión activa, mensajes y acciones

1. Ayuda contextual basada en misión y estado actual.
2. Notificaciones con prioridad, historial y lectura con Zira/Sabina.
3. Progreso real y siguiente acción sugerida.
4. Estados de acción y motivos de bloqueo, con datos del sistema que la ejecuta.
5. Alertas con umbrales acordados; no repetir la misma advertencia continuamente.

**Cubre:** 1, 2, 3, 8 y 9. P6 consume señales de P1/P2/P4/P5.

**Se acepta cuando:** Timmy ofrece una ayuda útil y un aviso nuevo no borra otro importante ni dispara varias voces a la vez.

### Fase 3 — Recompensas, suministros, inventario y colección

1. Panel compartido de misión completada con recompensas reales.
2. Recepción de módulos por misión y cantidades autorizadas.
3. Construir desde el inventario, con colocación/confirmación de P4 y actualización por el dueño del estado.
4. Cartas reales recibidas y colección Science ligada al guardado.
5. Confirmaciones de compra y errores específicos dentro del árbol existente.

**Cubre:** 4, 5, 6, 7 y 10. P2 verifica contenido científico; P5 determina recompensas y progresión.

**Se acepta cuando:** completar una misión entrega una sola vez lo que corresponde, colocar consume la unidad correcta y una carta recibida se puede volver a consultar.

### Fase 4 — Pausa, reanudación, checkpoint y reinicio

1. Volver al menú mantiene la sesión; Reanudar recupera la misma partida.
2. Pausar detiene reloj, consumos, movimiento y acciones según el contrato del equipo.
3. Ventanas distintas y amables para checkpoint Cadete y reinicio Ingeniero.
4. Restaurar o limpiar también los objetos 3D y el inventario; no solo los números del HUD.
5. Avisos de guardado correcto/error basados en el resultado real.

**Cubre:** 11 y 12. P1/P2/P4/P5 implementan estado; P6 su presentación y navegación.

**Se acepta cuando:** regresar al menú o repetir el tutorial no reinicia una partida por accidente, y el mensaje de recuperación describe lo que realmente se restaura.

### Fase 5 — Final de campaña y estados restantes

1. Victoria únicamente tras completar todas las misiones del catálogo vigente.
2. Resumen visual de logros y descubrimientos, y botones claros de colección/menú/nueva expedición.
3. Vacíos, carga y errores recuperables con una acción siguiente.
4. Ayuda de controles y explicación de base frente a robot.

**Cubre:** 13 y 14.

**Se acepta cuando:** la misión final dispara una única pantalla de cierre y la partida no continúa indefinidamente sin objetivo ni explicación.

### Fase 6 — Verificación completa y pulido final

- Recorridos Cadete/Ingeniero en EN/ES desde F5 y tutorial aislado con F6.
- Probar tutorial completo y salto, sin imponer Cadete si el perfil corresponde a Ingeniero.
- 1280×720, 960×540 y otra relación de aspecto; comprobar textos, foco, ventanas, clics y ayudas.
- Recursos agotados, batería sin carga, acciones simultáneas y alertas mientras se construye.
- Misión y recompensa repetidas, inventario vacío, compra sin estrellas y con prerrequisito pendiente.
- Pausa/reanudar, guardar/cargar, checkpoint, reinicio y todos los objetos del mundo.
- Campaña completa y cartas coleccionadas; no dar victoria con catálogo ausente.
- Voces por defecto y ajustes de sonido conservados. Probar también la exportación web y sus voces disponibles.
- Animaciones cortas y coherentes después de que lo anterior funcione; no necesitan nuevos modelos o ilustraciones para comenzar.

## Archivos propuestos y coordinación

### P6

- ui/game_overlay.gd y ui/game_overlay.tscn: estructura del HUD real, misión, entradas de menú y zonas de aviso.
- ui/timmy_assistant.gd: ayuda y lectura contextual, utilizando el helper de voz existente.
- ui/notification_center.gd: cola/historial de avisos y comunicaciones.
- ui/reward_panel.gd: presentación reutilizable de misión, carta y suministros.
- ui/science_collection.gd: colección real aprovechando la presentación del tablero actual.
- ui/run_result_panel.gd: ventanas de recuperación y final, con contenido según estado.
- ui/game_bridge.gd: ampliar el adaptador actual; no crear otra copia del estado o del balance del juego.
- Reutilizar y ajustar ui/hud.gd, ui/home_menu.gd, ui/section_menu.gd, ui/ui_kit.gd, ui/ui_icon.gd, ui/mission_list.gd y ui/upgrade_tree.gd.
- i18n/en.gd e i18n/es.gd: todas las claves; los textos de juego escritos en core se trasladan junto a su componente.
- ui/tests/: contratos de entrada, presentación, navegación, recompensas sin duplicar y casos de error.
- ui/INTEGRACION.md y docs/registro/puesto-6.md: mantener instrucciones y registro.

### Integración con los demás puestos

- P1: core/main.gd, core/juego.gd, GameState y escenas: montar el overlay, mantener sesión y sincronizar contratos.
- P2: reloj, recursos, umbrales, reglas de fallo, conversiones y fuentes científicas.
- P4: colocar/cancelar, objetos del mundo, movimiento y progreso de acciones.
- P5: misiones, triggers, suministros, cartera, colección y guardados.
- P3: se conservan modelos y arte. Se pide un recurso adicional solo si realmente falta.

La regla de propiedad de carpetas sigue vigente: los componentes visuales quedan en ui/ y sus conexiones a otros módulos se coordinan con el dueño. La integración no se reemplaza copiando los scripts antiguos de P6 sobre los nuevos.

## Verificación realizada para este plan

- Referencias remotas actualizadas y checkout limpio de unificacion_v1_proyect.
- Importación en Godot 4.7.2 de una copia separada.
- ui/tests/test_tutorial.gd: PASS, sin SCRIPT ERROR.
- tests/test_flujo.gd: FALLOS: 0, sin SCRIPT ERROR.
- Capturas nativas de inicio, tutorial, partida, menú, árbol EN/ES, misiones, Science, opciones y colocación.
- Confirmación en ejecución de misión visible vacía y medición de altura de batería.
- Diagnóstico de compra con HUD=10 frente a cartera=9 y de doble avance del reloj (1+1=2).

Las pruebas existentes no demuestran que los 14 puntos estén resueltos: no validan la descripción de misión visible, la restauración de una sesión ni la colección real. El test de flujo actual incluso espera el reinicio al volver al título; deberá actualizarse al corregir esa conducta. La importación/prueba aislada mostró un aviso de acceso al almacén de certificados del entorno, sin errores de compilación de los scripts.

Los guardados de control se redirigieron únicamente dentro de la copia de prueba; no se modificó ni borró el guardado de la persona usuaria. Este plan no incluye commit, push, publicación ni cambios de mecánicas.
