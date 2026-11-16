# Procedencia de los datos

*English summary: every NASA number used by the game, with its official source, download date, units and the transformation applied. Simulation rates that are not from NASA are labelled as game units.*

Cada número de NASA que usa el juego aparece aquí con su enlace oficial, fecha de descarga, unidades, transformación y supuestos.

## Datos de NASA usados

> El registro completo, con valores medidos, rangos, consultas exactas y diferenciación Luna vs. ISS, se consolidó en [DATOS_NASA.md](DATOS_NASA.md), y sus fórmulas escaladas al juego están en [CALCULOS_SISTEMA.md](CALCULOS_SISTEMA.md).

| Dato | Enlace oficial | Fecha | Unidades | Transformación | Dónde se usa |
|---|---|---|---|---|---|
| WRS / UPA (`Agua.pdf` SAE 2009-01-2352, ISS) | https://ntrs.nasa.gov/ (NASA MSFC) | 2026-11-14 | `kg/día`, `%`, `W` | Carga `9 kg/d` (6 trip.) escalada a `4` humanos (`6 kg/d`, `85%` recup.) + `743 W / 297 W` | [DATOS_NASA.md](DATOS_NASA.md), [CALCULOS_SISTEMA.md](CALCULOS_SISTEMA.md) |
| Radiación lunar `LRO CRaTER-D1D2` (basal + SPE 2012/2017/2024) | https://visualization.osdr.nasa.gov/radlab/api/ | 2026-11-14 | `μGy/h` | Basal `9.13 μGy/h`, picos `3,152–61,829 μGy/h` normalizados con $\log_{10}(\text{tasa}/\text{basal})$ | [DATOS_NASA.md](DATOS_NASA.md), [CALCULOS_SISTEMA.md](CALCULOS_SISTEMA.md) |
| Alertas SEP `DONKI` (ene 2012 y ene 2026) | https://api.nasa.gov/DONKI/SEP | 2026-11-14 | `pfu` (>10 MeV) | Referencia histórica SPE (`36,976 pfu` en ene 2026) | [DATOS_NASA.md](DATOS_NASA.md) |
| BVAD (`NASA/TP-2015-218570`) y Artemis LSH | https://ntrs.nasa.gov/ | 2026-11-14 | `kg/persona·d`, `W`, `kW` | `O₂` (`0.85 kg/d`), `H₂O`, `4BCO₂` (`975 W`), calefacción nocturna (`1.55 kW`) para 4 humanos | [DATOS_NASA.md](DATOS_NASA.md), [CALCULOS_SISTEMA.md](CALCULOS_SISTEMA.md) |
| VIPER, TRIDENT, Apollo ALSD y LCROSS | https://www.nasa.gov/ / https://ntrs.nasa.gov/ | 2026-11-14 | `Wh`, `W`, `cm/s`, `% wt` | Batería robot `5,420 Wh`, taladro `87–300 W`, hielo `5.6%` en masa | [DATOS_NASA.md](DATOS_NASA.md), [CALCULOS_SISTEMA.md](CALCULOS_SISTEMA.md) |
| Blindaje regolito e irradiancia Polo Sur | https://ntrs.nasa.gov/ | 2026-11-14 | `g/cm³`, `g/cm²`, `W/m²` | Regolito `>=400 g/cm²` (`~2 m`); solar `1,361 W/m² × 29% = 394.7 W/m²` | [DATOS_NASA.md](DATOS_NASA.md), [CALCULOS_SISTEMA.md](CALCULOS_SISTEMA.md) |

## Números que NO son de NASA

Los recursos y tasas de la simulación (energía, agua, oxígeno, escudo) son **unidades de juego** inventadas para enseñar relaciones básicas. No son datos de NASA ni una simulación verificada. Se rotulan así dentro del juego.

## Límites

- Un dato de la Estación Espacial Internacional no es un dato de la Luna: se dice cuál es cuál.
- No decimos que NASA avale el juego.
