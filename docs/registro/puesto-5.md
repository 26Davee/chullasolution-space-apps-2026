# Registro del puesto 5 · Misiones, progresión y árbol

Persona: Gael  ·  Usuario de GitHub: aax-j

Este archivo es **solo tuyo**: nadie más lo edita, así que no hay choques. Anota al momento, no al final. El puesto 1 junta los seis registros antes del envío.

## 1. Uso de IA

NASA pide reconocer todo lo hecho con ayuda de IA.

| Fecha y hora | Qué hice con IA (código, texto, imagen, sonido) | Herramienta | Dónde quedó (archivo) | Qué revisé o cambié yo |
|---|---|---|---|---|
| 2026-11-14 12:10 | Creación de diccionario técnico de variables y contratos entre puestos | Antigravity (Gemini) | `diccionario/README.md`, `diccionario/variables_sistema.json` | Revisé coincidencia con los 6 puestos, rangos y reglas de juego de Killawasi |
| 2026-11-14 13:01 | Auditoría pedagógica, corrección ortográfica y redacción adaptada a niños (7–12 años) de las 16 misiones y cartas educativas | Antigravity (Gemini) | `data/missions/missions.json` | Validé claridad infantil, tildes, enfoque de imprevistos en misiones 10–14 y solución anti-bloqueo de Misión 14 |
| 2026-11-14 13:17 | Auditoría científica, balanceo de costos (`1★/2★/3★`) y mejora de descripciones del Árbol de Habilidades | Antigravity (Gemini) | `data/missions/upgrades.json` | Corregí error conceptual de microgravedad lunar, ajusté Pico (`-8/-12` Vida) y Radar (`2s` reparación) |
| 2026-11-14 13:42 | Programación de persistencia, gestor de misiones, árbol tecnológico y pruebas automatizadas en GDScript | Antigravity (Gemini) | `progression/save_manager.gd`, `progression/mission_manager.gd`, `progression/tech_tree.gd`, `progression/test_progression.gd` | Probé compilación (`--check-only`) y ejecución headless en Godot 4.7.2 con `0` errores |

## 2. Material de terceros

Imagen, sonido, fuente, modelo o código que no hicimos nosotros.

| Qué es | Autor | Dónde lo conseguí (enlace) | Licencia | Dónde se usa |
|---|---|---|---|---|
| *Ninguno en Puesto 5* | — | — | — | — |

## 3. Datos de NASA

| Dato | Enlace oficial | Fecha de descarga | Unidades | Qué le hice (reducir, convertir…) | Dónde se usa |
|---|---|---|---|---|---|
| Irradiancia solar lunar (~1361 W/m²) y células fotovoltaicas | https://www.nasa.gov/glenn | 2026-11-14 | Concepto divulgativo / W/m² | Simplificado a analogía infantil («fotovoltaico», 3 capas) | `data/missions/missions.json` (`mision_01`), `upgrades.json` |
| Hallazgo de hielo polar en cráteres oscuros (Misión LCROSS 2009) | https://science.nasa.gov/mission/lcross/ | 2026-11-14 | Hecho histórico | Adaptado a explicación narrativa para niños (7–12 años) | `data/missions/missions.json` (`mision_02`) |
| Electrólisis y soporte vital en ciclo cerrado (ISS OGA / ECLSS) | https://www.nasa.gov/missions/station/iss-research/ | 2026-11-14 | Concepto de proceso | Explicado como «efecto dominó» y separación de agua | `data/missions/missions.json` (`mision_04`, `mision_11`), `upgrades.json` |
| Ciclo lunar (~28 días terrestres) y temperaturas nocturnas polares (LRO Diviner, $-240\ ^\circ\text{C}$) | https://science.nasa.gov/mission/lro/ | 2026-11-14 | Días terrestres y °C | Comprimido a ciclo de 8 min en juego (**unidades de juego**) | `data/missions/missions.json` (`mision_06`, `mision_07`) |
| Tormentas solares, partículas SEP y eventos de marzo 2012 (DONKI / SRAG / RadLab) | https://kauai.ccmc.gsfc.nasa.gov/DONKI/ | 2026-11-14 | Eventos históricos y alertas | Adaptado a alertas de cuenta atrás y cartas educativas | `data/missions/missions.json` (`mision_08`, `mision_10`, `mision_12`), `upgrades.json` |
| Herramientas geológicas Apollo (ALSD) y arquitectura Moon to Mars (Artemis) | https://www.nasa.gov/humans-in-space/artemis/ | 2026-11-14 | Concepto de ingeniería | Referencia divulgativa en cartas de herramientas y graduación | `data/missions/missions.json` (`mision_09`, `mision_16`), `upgrades.json` |

Recuerda: lo que **no** viene de NASA (por ejemplo, los números inventados del juego: puntajes de 1★/2★/3★, energía, vida, agua, oxígeno, tiempos de procesamiento y ciclo de 8 minutos) se rotula como **unidades de juego**.
