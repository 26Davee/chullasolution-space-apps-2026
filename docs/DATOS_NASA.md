# Datos Oficiales de la NASA — Referencia Base del Proyecto

> Este archivo centraliza **exclusivamente datos reales medidos o publicados por la NASA** (sin tasas inventadas de juego).
> Sustituye como fuente de verdad física a los borradores iniciales que usaban `vida`, `dia_luz_segundos: 300` y el diccionario provisional.
> Conforme a [DATA_PROVENANCE.md](DATA_PROVENANCE.md), se distingue explícitamente qué dato proviene de la **Luna** y qué dato proviene de sistemas equivalentes en la **Estación Espacial Internacional (ISS)**.

---

## 1. Tiempo y Ciclo Lunar (Entorno Lunar)

| Parámetro | Valor real | Unidad | Entorno | Fuente oficial / Documento |
|---|---|---|---|---|
| Duración del ciclo sinódico lunar completo | `29.53` | días terrestres (`708.72 h`) | Luna | Efemérides lunares estándar (NASA) |
| Fase de luz solar promedio por ciclo (ecuatorial/medio) | `14.765` | días terrestres (`354.36 h`) | Luna | Mitad del ciclo sinódico (`29.53 / 2`) |
| Fase de oscuridad promedio por ciclo | `14.765` | días terrestres (`354.36 h`) | Luna | Mitad del ciclo sinódico (`29.53 / 2`) |
| Iluminación solar acumulada anual (crestas del borde de Shackleton) | `70% - 80%+` (sombras extremas de `50+ h`) | `%` / `h` | Polo Sur Lunar | Estudios NASA Artemis / LRO LOLA sobre Polo Sur lunar |
| Temperaturas superficiales día / noche lunar | `> +120 °C` (sol directo) a `< -130 °C` (noche) | `°C` | Superficie Lunar | Documentación térmica Artemis Lunar Surface Habitat (NASA) |

---

## 2. Energía Solar, Hábitat Lunar y Consumo Eléctrico (4 Humanos)

| Parámetro | Valor real | Unidad | Entorno | Fuente oficial / Documento |
|---|---|---|---|---|
| Constante solar a 1 UA (TSI) | `1,361 - 1,366` (hasta `1,414` en perihelio) | `W/m²` | Espacio / Luna | NASA Solar Irradiance |
| Irradiancia útil en torres solares del borde de Shackleton | `1,300 - 1,370` (en fase iluminada) | `W/m²` | Polo Sur Lunar | NASA Artemis Polo Sur / Shackleton |
| Eficiencia eléctrica de paneles solares multiunión III-V (BOL) | `28 - 30+` | `%` | Espacial | NASA tecnología fotovoltaica espacial |
| Carga nominal del hábitat Artemis (4 tripulantes, operación activa) | `~20` | `kW` | Polo Sur Lunar | Estudios Artemis Lunar Surface Habitat (NASA JSC/LaRC) |
| Carga en modo latente / supervivencia nocturna / eclipse | `~2` (latente) a `~3` (soporte eclipse) | `kW` | Polo Sur Lunar | Estudios Artemis Lunar Surface Habitat (NASA JSC/LaRC) |
| Calefacción de reposición nocturna/eclipse (mantener interior ~20 °C) | `~1,550` (`1.55 kW`) | `W` | Polo Sur Lunar | Modelo térmico NASA LSH (retraer radiadores ahorra `~234 kWh`) |
| Rechazo térmico pico en verano polar (ATCS) | `~15` (`~48 m²` de radiadores desplegables) | `kWt` | Polo Sur Lunar | Arquitectura ATCS dual-loop Artemis LSH (NASA) |
| Volumen habitable / presurizado de referencia (4 tripulantes) | `127 - 190+` (presurizado total según diseño) | `m³` | Hábitat Lunar | NASA BVAD (`NASA/TP-2015-218570`) y estudios LAT |
| Sistema de recuperación de agua **WRS** (WPA + UPA) — **Procesando** | `743` (`320` WPA + `315` UPA + `94` AAA + `<=14` RPCM) | `W-hr/hr` (`W`) | ISS (ECLSS) | `Agua.pdf` (*SAE 2009-01-2352*, D. Layne Carter, NASA MSFC, p. 5) |
| Sistema de recuperación de agua **WRS** (WPA + UPA) — **Espera (Standby)** | `297` (`133` WPA + `56` UPA + `94` AAA + `<=14` RPCM) | `W-hr/hr` (`W`) | ISS (ECLSS) | `Agua.pdf` (*SAE 2009-01-2352*, p. 5) |
| Generador de oxígeno **OGA** — **Activo / Espera** | `3,000 - 3,573` (activo) / `382` (standby) | `W` | ISS (ECLSS) | Telemetría y especificaciones NASA ISS OGA |
| Remoción de $\text{CO}_2$ **CDRA** (ISS) vs **4BCO2** (Exploración 4 humanos) | `559` (CDRA prom.) / `975` prom. y `1,350` pico (4BCO2) | `W` | ISS / Lunar | NASA BVAD (`NASA/TP-2015-218570`) y desarrollo 4BCO2 Artemis |

---

## 3. Robot Explorador, Perforación y Hielo Lunar

| Parámetro | Valor real | Unidad | Entorno | Fuente oficial / Documento |
|---|---|---|---|---|
| Capacidad de batería del rover **VIPER** | `5,420` (`5.42 kWh`) | `Wh` | Polo Sur Lunar | Especificaciones NASA VIPER |
| Generación solar pico de **VIPER** | `450` (`~320 W` por panel activo) | `W` | Polo Sur Lunar | Especificaciones NASA VIPER |
| Potencia pico de movilidad / tracción (**VIPER**) | Hasta `~300` (en pendientes o regolito profundo) | `W` | Polo Sur Lunar | Documentación movilidad NASA VIPER |
| Velocidad nominal teleoperada (**VIPER**) | `~1` (`0.01 m/s` = `36 m/h`) | `cm/s` | Polo Sur Lunar | Documentación operaciones NASA VIPER |
| Taladro **TRIDENT** — profundidad e incrementos | Hasta `1` m en pasos de `10` cm; `< 1` hora por perforación completa | `m` / `h` | Polo Sur Lunar | NASA VIPER / Honeybee Robotics TRIDENT |
| Taladro **TRIDENT** — velocidad de giro y torque | `120` RPM, torque promedio `5.5` N·m | `RPM` / `N·m` | Polo Sur Lunar | Documentación técnica TRIDENT (NASA / USRA) |
| Taladro **TRIDENT** — consumo eléctrico | `<5` espera; `~20` nominal / `~87` barrena prom.; actuadores `200 W` + `200 W` (`175–300 W` máx); `+40` W calefactor | `W` | Polo Sur Lunar | Documentación técnica VIPER / TRIDENT (NASA NTRS) |
| Velocidad de perforación **Apollo ALSD** según terreno | `2-4` (basalto denso), `2-5` (permafrost denso), `6.5-13` (basalto vesicular), `>=30` (regolito suelto) | `cm/min` | Luna / Simulado | Reportes históricos Apollo ALSD (NASA) |
| Concentración de hielo de agua en regolito polar (**LCROSS**) | `5.6 ± 2.9` (`155 ± 12 kg` vapor/hielo observados) | `% en masa` | Cráter Cabeus (Luna) | Misión NASA LCROSS (Science / NASA) |

---

## 4. Soporte Vital para 4 Humanos (Agua, $\text{O}_2$ y Jardín Opcional)

| Parámetro | Valor real | Unidad | Entorno | Fuente oficial / Documento |
|---|---|---|---|---|
| Consumo metabólico de $\text{O}_2$ por humano | `0.84 - 0.89` (nominal `0.85`) | `kg O₂ / persona·día` | Humano (BVAD) | NASA BVAD (`NASA/TP-2015-218570`) |
| Producción de $\text{CO}_2$ por humano | `~1.00` (objetivo 4BCO2: `~4.16 kg/d` para 4 personas) | `kg CO₂ / persona·día` | Humano (BVAD) | NASA BVAD / especificaciones 4BCO2 |
| Capacidad de generación de $\text{O}_2$ del **OGA** | Hasta `9.25` máx. (`~5.4` cíclico nominal) | `kg O₂ / día` | ISS (ECLSS) | Especificaciones NASA ISS OGA |
| Estequiometría electrólisis del agua ($\text{2H}_2\text{O} \to \text{2H}_2 + \text{O}_2$) | `1.1259` (`18.015 / 16.000`) | `kg H₂O / kg O₂` | Física química | Estequiometría exacta |
| Agua potable mínima (bebida + preparación de comida) | `~2.00` bebida + `~0.50` comida (`2.50 - 2.70` mín.) | `kg H₂O / persona·día` | Humano (BVAD) | NASA BVAD |
| Agua de higiene / lavado (según arquitectura de misión) | `1.29` (restringida) hasta `3.5 - 5+` (completa) | `kg H₂O / persona·día` | Humano (BVAD) | NASA BVAD |
| Carga nominal de aguas residuales al **UPA** (orina + enjuague) | `9` para 6 tripulantes (`1.50` por persona) | `kg / día` | ISS (ECLSS) | `Agua.pdf` (*SAE 2009-01-2352*, p. 2) |
| Eficiencia mínima de recuperación de agua de orina (**UPA**) | `>= 85%` (`81%` medida en las primeras 6 semanas con `180 kg`) | `%` | ISS (ECLSS) | `Agua.pdf` (*SAE 2009-01-2352*, p. 2–4) |
| Relación observada en **WPA** (destilado vs condensado humedad) | `~270 kg` destilado UPA (`44%`) + `~340 kg` condensado (`56%`) | `kg` (`%`) | ISS (ECLSS) | `Agua.pdf` (*SAE 2009-01-2352*, p. 3) |
| Vapor latente humano (respiración + sudor -> condensado) | `2.28 - 2.95` (según protocolo de ejercicio) | `kg H₂O / persona·día` | Humano (BVAD) | NASA BVAD |
| Agua fecal no recuperada | `~0.10` | `kg H₂O / persona·día` | Humano (BVAD) | NASA BVAD |
| Cultivo espacial (*NASA Veggie / BPC* — Jardín opcional) | `10 - 30+` g $\text{O}_2/\text{m}^2\cdot\text{día}$; `20 - 25 m²` cubren `1` humano; iluminación LED `150 - 400+ W/m²` | varios | Cámara cultivo NASA | NASA Veggie / KSC Biomass Production Chamber |

---

## 5. Radiación Lunar, Tormentas Solares (SPE) y Blindaje de Regolito

> **Nota de auditoría sobre los `.svg` iniciales:** Los 3 archivos `.svg` en `datos de la radiacion/` contienen únicamente una imagen PNG rasterizada duplicada (hash SHA-256 `5ca18470d3e488ca`) de instrumentos de la ISS (`DosTel1`, `DosTel2`, `Lidal`, `REM-Lid`) fechada `00:00 Mar 1, 2022 – 00:00 Mar 2, 2022`. Por tanto fueron descartados y sustituidos por consultas numéricas reales al endpoint público **NASA OSDR RadLab API** y **NASA CCMC DONKI**.

| Parámetro / Evento | Valor real medido | Unidad | Fuente y consulta exacta |
|---|---|---|---|
| Fondo tranquilo lunar **GCR** en órbita LRO (`10–12 ene 2012`, 72 h) | Media **`9.13`** (rango `8.19 – 10.10`, mediana `9.11`) | `μGy/h` (`~0.219 mGy/día`) | NASA OSDR RadLab API (`LRO`, `CRaTER-D1D2`) |
| Fondo basal **GCR** en superficie lunar | `~13.29` (`~0.319 mGy/d`; dosis equiv. `~0.8 - 0.9 mSv/día`) | `μGy/h` / `mSv/día` | Calibración LRO CRaTER / LND superficie lunar |
| **SPE Enero 2012** (llamarada M8.7 `2012-01-23T03:59Z`, `22–28 ene 2012`, 167 h) | Media **`10,619.42`**; mediana `1,831.92`; **pico `61,829.17`** (`61.83 mGy/h`, `~6,770×` basal) el `2012-01-24T16:06:41`; dosis acumulada detectores Si `~185 mGy` | `μGy/h` / `mGy` | NASA RadLab API (`LRO`, `CRaTER-D1D2`) + NASA DONKI (`2012-01-23T04:49Z-SEP-001`) |
| **SPE Septiembre 2017** (`09–14 sep 2017`, 145 h) | Media **`5,274.29`**; mediana `1,452.33`; **pico `22,968.75`** (`22.97 mGy/h`, `~2,515×` basal) el `2017-09-11T05:02:38` | `μGy/h` | NASA RadLab API (`LRO`, `CRaTER-D1D2`) |
| **Tormenta Mayo 2024** (`10–16 may 2024`, 168 h) | Media **`597.23`**; mediana `371.26`; **pico `3,151.75`** (`3.15 mGy/h`, `~345×` basal) el `2024-05-14T02:59:59` | `μGy/h` | NASA RadLab API (`LRO`, `CRaTER-D1D2`) |
| **SPE Enero 2026** (llamarada X1.9 `2026-01-18T18:09Z` + choque `2026-01-19T18:55Z`) | GOES `>10 MeV` alcanzó **`36,976 pfu`** (tormenta **S4 Severa**); **0 registros en RadLab aún** | `pfu` (>10 MeV) | NASA DONKI (`20260119-AL-006`) / NOAA SWPC *(no ingestado aún en RadLab)* |
| **Octubre 2003 (Halloween)** | Evento extremo histórico que saturó/dañó MARIE en Marte; **0 registros en RadLab ISS** para esas fechas | — | Documentación NASA / RadLab API (`count = 0` para `2003-10-28..31`) |
| Densidad aparente del regolito lunar | `1.1 - 1.5` (0–20 cm), `1.5 - 1.8` (>30–60 cm), `1.9 - 2.0` (compactado profundo) | `g/cm³` | Estudios geotécnicos lunares NASA |
| Blindaje mínimo de regolito contra GCR/SPE | **`>= 400`** ($\approx \mathbf{2.0 - 2.66\text{ m}}$ a `1.5–2.0 g/cm³`; `1.5–2.5 m` típico; `700 g/cm²` para SPE severos). Capas finas `100–200 g/cm²` generan neutrones secundarios | `g/cm²` / `m` | Estudios arquitectura radiación lunar NASA |

---

## 6. URLs de consulta reproducibles (APIs públicas NASA sin API key privada)

- **NASA OSDR RadLab API (basal LRO CRaTER):**
  `https://visualization.osdr.nasa.gov/radlab/api/?query=(spacecraft=LRO)%20AND%20(timestamp>=2012-01-10T00:00:00)%20AND%20(timestamp<=2012-01-12T23:59:59)&fields=timestamp,instrument_id,spacecraft,absorbed_dose_rate,dose_equivalent_rate,flux&format=json`
- **NASA OSDR RadLab API (SPE enero 2012 LRO CRaTER):**
  `https://visualization.osdr.nasa.gov/radlab/api/?query=(spacecraft=LRO)%20AND%20(timestamp>=2012-01-22T00:00:00)%20AND%20(timestamp<=2012-01-28T23:59:59)&fields=timestamp,instrument_id,spacecraft,absorbed_dose_rate,dose_equivalent_rate,flux&format=json`
- **NASA CCMC DONKI SEP (alertas con flujo `pfu`):**
  `https://api.nasa.gov/DONKI/notifications?startDate=2026-01-18&endDate=2026-01-21&type=SEP&api_key=DEMO_KEY`
