---
name: killawasi-escena-lunar-godot
description: Construir y revisar la escena lunar de Killawasi en Godot 4.7 GL Compatibility (terreno facetado lila, rocas, cráteres, camino con luces, cielo estrellado, sol cálido, domo, brillo) para que se vea como la imagen de referencia. Úsala al crear o mejorar el mundo 3D, la iluminación o el aspecto general.
---

# Killawasi · escena lunar

Referencia: la "Vista de conjunto" de la Guía visual 3D de Carlos (maqueta lunar lila, domo turquesa transparente, paneles azules, camino con luces ámbar, la Tierra y el Sol al fondo). Esa imagen manda. Comparar siempre contra ella.

## Qué hace que se vea bien
1. **Terreno facetado, no liso.** Plano subdividido (unos 80×80 cuadros) con ruido suave de altura (FastNoiseLite, amplitud baja cerca de la base, más alta lejos), y **caras planas** (sin suavizar normales). Zona de juego casi plana para que las casillas se alineen.
2. **Color del regolito lila** #7C7890 con variación de tono por zonas. Nada de gris neutro.
3. **Rocas low-poly**: icosferas de 1–2 subdivisiones, escaladas de forma irregular (1 : 0.6 : 0.9), vértices desplazados al azar un 15 %, caras planas, tonos entre #6A6580 y #8D88A3. Agrupadas de 2–4, algunas grandes y lejos, otras chicas y cerca del camino. Montañas del fondo = conos facetados grandes, más oscuros por la distancia.
4. **Cráteres**: disco hundido con borde elevado (anillo) más claro. Los que tienen hielo llevan cristales cian facetados y un leve brillo.
5. **Camino**: cinta redondeada gris claro con luces ámbar (`emission`) cada ~1,5 u, que une cápsula, módulos y cráter.
6. **Cielo**: azul muy oscuro #04122E con estrellas (shader sencillo de puntos o un `PanoramaSky` con textura), Tierra como esfera azul con textura simple y Sol como esfera emisiva ámbar con halo. Están lejos y no se mueven con la cámara.

## Luz y ambiente (Godot 4.7, GL Compatibility)
- `DirectionalLight3D`: color cálido #FFD9A0, energía 1,2–1,5, inclinada unos 35° sobre el horizonte y de lado para que haya sombras largas. `shadow_enabled = true`, ajustar `directional_shadow_max_distance` a unos 40 u.
- `WorldEnvironment`: `ambient_light_source = COLOR` con un violeta frío (#6F6A9A), energía 0.6–0.8. `tonemap_mode` = Filmic o ACES. **Glow activado** (intensidad ~0.8, umbral ~1.0) para que ámbar y cian emisivos brillen. Niebla ligera de profundidad con color lila oscuro para separar planos. Verificar en pantalla que el glow se vea en Compatibility.
- En modo Compatibility **no funcionan** SSAO, SSIL ni SDFGI. No los uses. Para dar profundidad, usa sombras, niebla y variación de color.
- De noche: bajar la energía del sol y el ambiente (con tween de 2–3 s al recibir `GameState.ciclo_solar_cambiado`), subir el brillo de luces ámbar, oscurecer el azul de los paneles.

## Domo / escudo
`media_esfera` (ver skill `killawasi-arte-3d-godot`) con material: albedo cian alpha 0.18, `transparency = ALPHA`, `cull_mode = DISABLED`, `shading_mode = UNSHADED` o roughness 0.1, y un borde de anillo más claro en el suelo. Cuatro estados según escudo: 100 (nítido), 70 (ligeramente más tenue), 30 (parpadeo suave), 0 (solo contorno apagado).

## Cámara
Semiisométrica ~45°, FOV 35–40 (o proyección ortogonal si el equipo la elige), mirando al centro de la base. Altura y distancia para ver cápsula, módulos y camino a la vez, como en la referencia.

## Cómo revisar (bucle de captura)
Sin ver la imagen no se puede juzgar. Hacer esto después de cada cambio importante:
1. Ejecutar la escena y guardar una captura: `get_viewport().get_texture().get_image().save_png("user://captura.png")` (por ejemplo con la tecla F12 en un script de depuración).
2. Ponerla al lado de la referencia y revisar: ¿colores lila y turquesa?, ¿sombras suaves?, ¿luces ámbar brillando?, ¿piezas redondeadas?, ¿se distingue cada módulo?
3. Anotar lo que no coincide y corregir. Repetir hasta que se parezca.
4. Si el agente tiene un MCP de Godot con captura de pantalla, usarlo en lugar de guardar archivos.

## Errores comunes que hay que evitar
Suelo gris liso · rocas esféricas suavizadas · luz blanca desde arriba (sin sombras largas) · ausencia de glow · domo opaco · camino sin luces · cielo negro puro sin estrellas · cámara con perspectiva fuerte que deforma · más de 200 nodos de rocas sin `MultiMeshInstance3D` (usar MultiMesh para rocas repetidas).
