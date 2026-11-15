# Registro del puesto 5 · Misiones, progresión y árbol

Persona: Gael  ·  Usuario de GitHub: aax-j

Este archivo es **solo tuyo**: nadie más lo edita, así que no hay choques. Anota al momento, no al final. El puesto 1 junta los seis registros antes del envío.

## 1. Uso de IA

NASA pide reconocer todo lo hecho con ayuda de IA.

| Fecha y hora | Qué hice con IA (código, texto, imagen, sonido) | Herramienta | Dónde quedó (archivo) | Qué revisé o cambié yo |
|---|---|---|---|---|
| 2026-11-14 12:10 | Creación de diccionario técnico de variables y contratos entre puestos | Antigravity (Gemini) | `diccionario/README.md`, `diccionario/variables_sistema.json` | Revisé coincidencia con los 6 puestos, rangos y reglas de juego de Killawasi |
| 2026-11-14 13:01 | Auditoría pedagógica, corrección ortográfica y redacción adaptada a niños (7–12 años) de las 16 misiones y cartas educativas | Antigravity (Gemini) | `data/missions/missions.json` | Validé claridad infantil, tildes, enfoque de imprevistos en misiones 10–14 y solución anti-bloqueo de Misión 14 |
| 2026-11-14 13:17 | Auditoría científica, balanceo de costos (`1★/2★/3★`) y mejora de descripciones del Árbol de Habilidades | Antigravity (Gemini) | `data/missions/upgrades.json` | Corregí error conceptual de microgravedad lunar, ajusté Pico y Radar (`2s` reparación) |
| 2026-11-14 13:42 | Programación de persistencia, gestor de misiones, árbol tecnológico y pruebas automatizadas en GDScript | Antigravity (Gemini) | `progression/save_manager.gd`, `progression/mission_manager.gd`, `progression/tech_tree.gd`, `progression/test_progression.gd` | Probé compilación (`--check-only`) y ejecución headless en Godot 4.7.2 con `0` errores |
| 2026-11-14 17:30 | Pivote narrativo y mecánico a robot explorador: eliminación de barra `vida`, drenaje continuo de batería en expedición, actualización de misiones (`mision_02`, `05`, `08`, `10`, `11`, `12`, `14`, `15`, `16`), rama `soporte_vital` y soporte bilingüe (`es`/`en`) | Antigravity (Gemini) | `core/game_state.gd`, `core/juego.gd`, `i18n/`, `data/missions/`, `progression/`, `diccionario/` | Validación JSON, compilación `--check-only` y pruebas headless en Godot 4.7.2 con `0` fallos |

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
| NASA/JSC ISS ECLSS Water Recovery System (`SAE 2009-01-2352`, `Agua.pdf`) | NASA Johnson Space Center / SAE | 2026-11-14 | Recuperación % y W-hr/hr | Referencia técnica de recuperación de agua (UPA ≥85%, WPA) y consumo energético (743 W-hr/hr activo vs 297 W-hr/hr espera) | `docs/registro/puesto-5.md`, `data/missions/` |
| Series de dosis de radiación en `μGy/hour` (`DosTel1`, `DosTel2`, `Lidal`, `REM-Lid`) | NASA / RadLab SVGs | 2026-11-14 | μGy/hour | Calibración conceptual para mitigación y alertas de tormentas solares sobre electrónica del robot y el domo | `data/missions/missions.json` (`mision_08`, `mision_10`), `upgrades.json` |
| Misiones de robótica lunar NASA (CADRE, VIPER) | https://www.nasa.gov/mission/viper/ | 2026-11-14 | Concepto operativo | Referencia para la recarga solar del robot explorador en estaciones del domo (`mision_05`) | `data/missions/missions.json` (`mision_05`) |

Recuerda: lo que **no** viene de NASA (por ejemplo, los números inventados del juego: puntajes de 1★/2★/3★, energía, agua, oxígeno, escudo, tiempos de procesamiento y ciclo de 8 minutos) se rotula como **unidades de juego**.
