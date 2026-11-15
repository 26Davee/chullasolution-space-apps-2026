# Referencia Completa de Datos NASA, Fuentes y Cálculos del Sistema

> Documento unificado que reúne en un solo lugar la información actualmente repartida entre:
> - [DATOS_NASA.md](DATOS_NASA.md) — valores físicos medidos o publicados por la NASA.
> - [CALCULOS_SISTEMA.md](CALCULOS_SISTEMA.md) — fórmulas de conversión física hacia la escala del juego (`%/s`).
> - [DATA_PROVENANCE.md](DATA_PROVENANCE.md) — trazabilidad oficial, enlaces, fechas y límites de uso.

---

## 1. De dónde sale cada dato (Procedencia y Fuentes Oficiales)

Conforme a [DATA_PROVENANCE.md](DATA_PROVENANCE.md), se distingue explícitamente qué dato proviene de la **Luna** y qué dato proviene de sistemas equivalentes en la **Estación Espacial Internacional (ISS)**.

| Bloque de datos | Fuente oficial / Documento | Enlace / Endpoint oficial | Fecha de registro | Entorno | Qué se tomó / transformó |
|---|---|---|---|---|---|
| **Recuperación de agua WRS / UPA** | `Agua.pdf` (*SAE 2009-01-2352*, D. Layne Carter, NASA MSFC) | https://ntrs.nasa.gov/ | 2026-11-14 | ISS (ECLSS) | Carga `9 kg/día` (6 trip.) escalada a `4` humanos (`6 kg/día`, `>=85%` recup.) + consumos `743 W` / `297 W` |
| **Radiación lunar basal y tormentas SPE** | NASA OSDR RadLab API (`LRO`, `CRaTER-D1D2`) | https://visualization.osdr.nasa.gov/radlab/api/ | 2026-11-14 | Luna (órbita/superficie) | Basal `9.13 μGy/h` (`~13.29` sup.) y picos SPE `3,152–61,829 μGy/h` normalizados con $\log_{10}(\text{tasa}/\text{basal})$ |
| **Alertas solares SEP** | NASA CCMC DONKI (`SEP`) / NOAA SWPC | https://api.nasa.gov/DONKI/SEP | 2026-11-14 | Espacio / Sol | Secuencia llamarada → CME → SEP (ene 2012) y evento ene 2026 S4 (`36,976 pfu` >10 MeV) |
| **Metabolismo humano, CO₂ y Hábitat** | NASA BVAD (`NASA/TP-2015-218570`) y Artemis LSH (JSC/LaRC) | https://ntrs.nasa.gov/ | 2026-11-14 | Humano / Hábitat Lunar | `O₂` (`0.85 kg/persona·d`), `H₂O` (`2.50 kg/d`), `4BCO₂` (`975 W`), calefacción nocturna (`1.55 kW`) para 4 humanos |
| **Generador de O₂ (`OGA`)** | Telemetría y especificaciones NASA ISS OGA | https://ntrs.nasa.gov/ | 2026-11-14 | ISS (ECLSS) | `3,000–3,573 W` activo / `382 W` espera; máx. `9.25 kg O₂/día` (`1.1259 kg H₂O / kg O₂`) |
| **Robot, Taladro e Hielo lunar** | NASA VIPER, Honeybee TRIDENT (USRA), Apollo ALSD y LCROSS | https://www.nasa.gov/ / https://ntrs.nasa.gov/ | 2026-11-14 | Polo Sur Lunar | Batería `5,420 Wh`, taladro `87–300 W`, concentración de hielo `5.6%` en masa |
| **Paneles solares y blindaje de regolito** | NASA Solar Irradiance, LRO LOLA (Shackleton) y estudios geotécnicos NASA | https://ntrs.nasa.gov/ | 2026-11-14 | Polo Sur Lunar | Irradiancia `1,361 W/m²` × `29%` = `394.7 W/m²`; blindaje regolito `>=400 g/cm²` (`~2.0–2.66 m`) |
| **Jardín espacial (opcional)** | NASA Veggie / KSC Biomass Production Chamber (BPC) | https://www.nasa.gov/ | 2026-11-14 | Cámara de cultivo NASA | `10–30+ g O₂/m²·día`, LEDs `150–400+ W/m²` (`20–25 m²` cubren `1` humano) |

### Nota de auditoría sobre los `.svg` iniciales
Los 3 archivos `.svg` originales en `datos de la radiacion/` (`Caso sencillo_28 al 30 de octubre de 2003.svg`, `Caso medio_ 23 de enero de 2012.svg`, `Caso extremo_19 de enero de 2026.svg`) contenían únicamente la misma imagen PNG rasterizada duplicada (hash SHA-256 `5ca18470d3e488ca`) de instrumentos de la ISS (`DosTel1`, `DosTel2`, `Lidal`, `REM-Lid`) fechada `00:00 Mar 1, 2022 – 00:00 Mar 2, 2022`. Por rigor científico fueron **descartados** y sustituidos por consultas numéricas reales a **NASA OSDR RadLab API** y **NASA CCMC DONKI**.

### URLs reproducibles (APIs públicas sin API key privada)
- **RadLab API (basal LRO CRaTER, 10–12 ene 2012):**
  `https://visualization.osdr.nasa.gov/radlab/api/?query=(spacecraft=LRO)%20AND%20(timestamp>=2012-01-10T00:00:00)%20AND%20(timestamp<=2012-01-12T23:59:59)&fields=timestamp,instrument_id,spacecraft,absorbed_dose_rate,dose_equivalent_rate,flux&format=json`
- **RadLab API (SPE enero 2012, LRO CRaTER):**
  `https://visualization.osdr.nasa.gov/radlab/api/?query=(spacecraft=LRO)%20AND%20(timestamp>=2012-01-22T00:00:00)%20AND%20(timestamp<=2012-01-28T23:59:59)&fields=timestamp,instrument_id,spacecraft,absorbed_dose_rate,dose_equivalent_rate,flux&format=json`
- **DONKI SEP (notificaciones con `pfu`):**
  `https://api.nasa.gov/DONKI/notifications?startDate=2026-01-18&endDate=2026-01-21&type=SEP&api_key=DEMO_KEY`

---

## 2. Datos Físicos Oficiales por Subsistema

### 2.1 Tiempo y Entorno Lunar
| Parámetro | Valor real | Unidad | Entorno | Fuente |
|---|---|---|---|---|
| Ciclo sinódico lunar completo | `29.53` (`708.72 h`) | días terrestres | Luna | Efemérides lunares NASA |
| Fase promedio de luz / oscuridad | `14.765` cada una (`354.36 h`) | días terrestres | Luna | Mitad del ciclo sinódico (`29.53 / 2`) |
| Iluminación solar acumulada (borde de Shackleton) | `70% - 80%+` (sombras extremas `50+ h`) | `%` / `h` | Polo Sur Lunar | NASA Artemis / LRO LOLA |
| Temperaturas superficiales día / noche | `> +120 °C` a `< -130 °C` | `°C` | Superficie Lunar | Artemis Lunar Surface Habitat (NASA) |

### 2.2 Energía Solar, Hábitat y Cargas Eléctricas (`4` Humanos)
| Parámetro | Valor real | Unidad | Entorno | Fuente |
|---|---|---|---|---|
| Constante solar a 1 UA (TSI) | `1,361 - 1,366` (hasta `1,414` perihelio) | `W/m²` | Espacio / Luna | NASA Solar Irradiance |
| Irradiancia útil (torres borde de Shackleton) | `1,300 - 1,370` | `W/m²` | Polo Sur Lunar | NASA Artemis Polo Sur |
| Eficiencia paneles multiunión III-V (BOL) | `28 - 30+` | `%` | Espacial | NASA fotovoltaica espacial |
| Carga nominal hábitat Artemis (4 trip.) | `~20` | `kW` | Polo Sur Lunar | NASA JSC / LaRC (LSH) |
| Carga en modo latente / eclipse | `~2` (latente) a `~3` (eclipse) | `kW` | Polo Sur Lunar | NASA JSC / LaRC (LSH) |
| Calefacción nocturna/eclipse (~20 °C interior) | `~1,550` (`1.55 kW`) | `W` | Polo Sur Lunar | Modelo térmico NASA LSH |
| Rechazo térmico pico en verano polar (ATCS) | `~15` (`~48 m²` radiadores) | `kWt` | Polo Sur Lunar | Arquitectura ATCS Artemis LSH |
| Volumen presurizado de referencia (4 trip.) | `127 - 190+` | `m³` | Hábitat Lunar | NASA BVAD (`NASA/TP-2015-218570`) |
| **WRS** (WPA + UPA) — Procesando / Espera | `743` (`320+315+94+<=14`) / `297` (`133+56+94+<=14`) | `W-hr/hr` (`W`) | ISS (ECLSS) | `Agua.pdf` (*SAE 2009-01-2352*, p. 5) |
| **OGA** (Generador O₂) — Activo / Espera | `3,000 - 3,573` / `382` | `W` | ISS (ECLSS) | Especificaciones NASA ISS OGA |
| Remoción de CO₂ (**CDRA** vs **4BCO2**) | `559` (CDRA) / `975` prom. y `1,350` pico (`4BCO2`) | `W` | ISS / Lunar | NASA BVAD y desarrollo 4BCO2 Artemis |

### 2.3 Robot Explorador (`VIPER`), Taladro (`TRIDENT` / `Apollo ALSD`) e Hielo (`LCROSS`)
| Parámetro | Valor real | Unidad | Entorno | Fuente |
|---|---|---|---|---|
| Capacidad de batería del rover **VIPER** | `5,420` (`5.42 kWh`) | `Wh` | Polo Sur Lunar | Especificaciones NASA VIPER |
| Generación solar pico **VIPER** | `450` (`~320 W` por panel activo) | `W` | Polo Sur Lunar | Especificaciones NASA VIPER |
| Potencia pico de movilidad (**VIPER**) | Hasta `~300` | `W` | Polo Sur Lunar | Documentación movilidad NASA VIPER |
| Velocidad nominal teleoperada (**VIPER**) | `~1` (`0.01 m/s` = `36 m/h`) | `cm/s` | Polo Sur Lunar | Documentación operaciones VIPER |
| Taladro **TRIDENT** (profundidad y ritmo) | Hasta `1` m en pasos de `10` cm (`< 1 h`), `120` RPM, `5.5` N·m | varios | Polo Sur Lunar | NASA VIPER / Honeybee TRIDENT |
| Taladro **TRIDENT** (consumo eléctrico) | `<5` espera; `~20` nom. / `~87` barrena prom.; actuadores `200 W + 200 W` (`175–300 W` máx.); `+40` W calefactor | `W` | Polo Sur Lunar | Documentación técnica TRIDENT (NASA NTRS) |
| Velocidad perforación **Apollo ALSD** | `2-4` (basalto denso), `2-5` (permafrost), `6.5-13` (basalto vesic.), `>=30` (regolito suelto) | `cm/min` | Luna / Simulado | Reportes históricos Apollo ALSD |
| Concentración de hielo (**LCROSS**) | `5.6 ± 2.9` (`155 ± 12 kg` vapor/hielo observados) | `% en masa` | Cráter Cabeus | Misión NASA LCROSS (Science/NASA) |

### 2.4 Soporte Vital para `4` Humanos (`BVAD`, `WRS`, `OGA` y `Veggie`)
| Parámetro | Valor real | Unidad | Entorno | Fuente |
|---|---|---|---|---|
| Consumo metabólico de O₂ | `0.84 - 0.89` (nominal `0.85`) | `kg O₂ / persona·día` | Humano (BVAD) | NASA BVAD |
| Producción de CO₂ | `~1.00` (`~4.16 kg/d` para 4 personas) | `kg CO₂ / persona·día` | Humano (BVAD) | NASA BVAD / 4BCO2 |
| Capacidad generación O₂ (**OGA**) | Hasta `9.25` máx. (`~5.4` cíclico) | `kg O₂ / día` | ISS (ECLSS) | Especificaciones NASA ISS OGA |
| Electrólisis ($\text{2H}_2\text{O} \to \text{2H}_2 + \text{O}_2$) | `1.1259` (`18.015 / 16.000`) | `kg H₂O / kg O₂` | Química | Estequiometría exacta |
| Agua potable mínima | `~2.00` bebida + `~0.50` comida (`2.50 - 2.70`) | `kg H₂O / persona·día` | Humano (BVAD) | NASA BVAD |
| Agua de higiene | `1.29` (restringida) a `3.5 - 5+` (completa) | `kg H₂O / persona·día` | Humano (BVAD) | NASA BVAD |
| Carga nominal al **UPA** | `9` para 6 tripulantes (`1.50` / persona) | `kg / día` | ISS (ECLSS) | `Agua.pdf`, p. 2 |
| Eficiencia recuperación **UPA** | `>= 85%` (`81%` en primeras 6 semanas con `180 kg`) | `%` | ISS (ECLSS) | `Agua.pdf`, p. 2–4 |
| Proporción en **WPA** | `~270 kg` destilado UPA (`44%`) + `~340 kg` condensado (`56%`) | `kg` (`%`) | ISS (ECLSS) | `Agua.pdf`, p. 3 |
| Vapor latente humano (condensado) | `2.28 - 2.95` | `kg H₂O / persona·día` | Humano (BVAD) | NASA BVAD |
| Agua fecal no recuperada | `~0.10` | `kg H₂O / persona·día` | Humano (BVAD) | NASA BVAD |
| Cultivo (**Veggie / BPC**) | `10 - 30+ g O₂/m²·d`; `20 - 25 m²` = `1` humano; LED `150 - 400+ W/m²` | varios | Cámara cultivo | NASA Veggie / KSC BPC |

### 2.5 Radiación Lunar y Blindaje de Regolito
| Parámetro / Evento | Valor real medido | Unidad | Fuente |
|---|---|---|---|
| Fondo tranquilo **GCR** órbita LRO (`10–12 ene 2012`) | Media `9.13` (`8.19–10.10`, mediana `9.11`) | `μGy/h` | NASA RadLab (`LRO CRaTER-D1D2`) |
| Fondo basal **GCR** en superficie lunar | `~13.29` (`~0.319 mGy/d`; `~0.8–0.9 mSv/día`) | `μGy/h` / `mSv/d` | LRO CRaTER / LND |
| **SPE Enero 2012** (`22–28 ene 2012`, M8.7) | Media `10,619.42`; **pico `61,829.17`** (`~6,770×` basal); `~185 mGy` acum. | `μGy/h` / `mGy` | RadLab (`CRaTER-D1D2`) + DONKI (`2012-01-23T04:49Z-SEP-001`) |
| **SPE Septiembre 2017** (`09–14 sep 2017`) | Media `5,274.29`; **pico `22,968.75`** (`~2,515×` basal) | `μGy/h` | RadLab (`CRaTER-D1D2`) |
| **Tormenta Mayo 2024** (`10–16 may 2024`) | Media `597.23`; **pico `3,151.75`** (`~345×` basal) | `μGy/h` | RadLab (`CRaTER-D1D2`) |
| **SPE Enero 2026** (X1.9 `18 ene` + choque `19 ene`) | GOES `>10 MeV` pico `36,976 pfu` (**S4 Severa**); 0 filas aún en RadLab | `pfu` | NASA DONKI (`20260119-AL-006`) / NOAA SWPC |
| **Octubre 2003 (Halloween)** | Evento extremo que dañó MARIE en Marte; 0 registros RadLab ISS | — | NASA / RadLab (`count = 0`) |
| Densidad aparente del regolito | `1.1–1.5` (0–20 cm), `1.5–1.8` (>30–60 cm), `1.9–2.0` (compactado) | `g/cm³` | Geotecnia lunar NASA |
| Blindaje mínimo de regolito contra GCR/SPE | `>= 400` (`~2.0–2.66 m` de espesor; `700 g/cm²` SPE severos) | `g/cm²` / `m` | Estudios radiación lunar NASA |

---

## 3. Fórmulas y Conversión a Escala del Juego

### 3.1 Reglas de diseño vigentes del motor ([CALCULOS_SISTEMA.md](CALCULOS_SISTEMA.md))
- **Sin barra de `vida`:** ni los humanos ni el robot usan barra de vida.
- **Dos energías separadas:** **Energía del Robot** + **Energía Total de la Base**.
- **Recarga (*Descansar*):** al acercarse al Domo y pulsar *Descansar*, la Base transfiere energía al Robot (`Energía Base` baja, `Energía Robot` sube).
- **Tripulación fija:** **`4` humanos** en el Domo.
- **Ciclo temporal:** **`480 s` = `29.53 días` terrestres** (`240 s` luz + `240 s` noche lunar), con rollover calendario (`30 días -> +1 mes`, `12 meses -> +1 año`):
  - $1\text{ s real} = 0.061521\text{ días} = 1.4765\text{ horas}$
  - $1\text{ día simulado} = 16.255\text{ s reales}$ | $1\text{ hora simulada} = 0.6773\text{ s reales}$

### 3.2 Fórmulas principales
1. **Generación por Panel Solar (`25 m²`):**
   $$P_{\text{específica}} = 1,361\text{ W/m}^2 \times 0.29 = 394.7\text{ W/m}^2 \implies 25\text{ m}^2 \times 0.3947\text{ kW/m}^2 = \mathbf{9.87\text{ kW}}$$
   En escala juego: $+14.569\text{ kWh/s}$ de día ($\mathbf{+0.729\%/\text{s}}$ sobre banco de `2,000 kWh`), cubriendo con margen el mínimo vital nocturno de **$\mathbf{4.718\text{ kW}}$** (`0.743 WRS + 1.450 OGA prom. + 0.975 4BCO2 + 1.550 calefacción`).
2. **Consumo de $\text{O}_2$ y $\text{H}_2\text{O}$ (4 humanos):**
   - $\dot{m}_{\text{O}_2} = 4 \times 0.85 = 3.40\text{ kg/día} = 0.2092\text{ kg/s}$ (`50.20 kg` por noche de `240 s`).
   - Electrólisis en OGA: $3.40 \times 1.1259 = 3.828\text{ kg H}_2\text{O/día} = 0.2355\text{ kg/s}$.
   - Agua potable mínima ($10.00\text{ kg/día}$) menos lo recuperado por **UPA** ($85\%$ de $6\text{ kg/día} = 5.10\text{ kg/día}$) y condensado ($\sim 9.12\text{ kg/día}$): reposición neta real de **$5.1 - 9.5\text{ kg H}_2\text{O/día}$** ($0.31 - 0.59\text{ kg/s}$).
3. **Jardín opcional (`10 m²`):** $+0.30\text{ kg O}_2/\text{día}$ ($\approx 8.8\%$ de la demanda de 4 humanos) y consume `2.50 kW` en LEDs.
4. **Robot (`VIPER` `5.42 kWh`) + Taladro + Hielo:**
   - Excursión Base $\leftrightarrow$ Cráter ($4\text{ h}$ equiv. a `300 W` = `1.20 kWh`): **`-22.1%`** batería del robot.
   - Perforación `1 m`: **`127 Wh`** (`-2.34%`) nominal a **`300 Wh`** (`-5.54%`) pico.
   - Hielo por regolito (`LCROSS`): $\text{Hielo}_{\text{kg}} = \text{Regolito}_{\text{kg}} \times 0.056$.
   - Recarga al `100%` en Domo ($\eta_{\text{carga}} = 0.90$): toma $\frac{5.42}{0.90} = \mathbf{6.02\text{ kWh}}$ de la Base (`0.301%` de `2,000 kWh` o `3.01%` de `200 kWh`).
5. **Degradación del Escudo por Radiación (`LRO CRaTER`):**
   Factor normalizado logarítmico $F = \log_{10}(\text{tasa}/\text{basal})$:
   - Basal ($1\times$): $F = 0$
   - Moderada (`May 2024`, $345\times$): $F \approx 2.54$
   - Fuerte (`Sep 2017`, $2,515\times$): $F \approx 3.40$
   - Extrema (`Ene 2012`, $6,770\times$): $F \approx 3.83$

### 3.3 Tabla Maestra de Barras (`0 – 100%`)
*(Las capacidades de tanque/banco son **Constantes de Diseño del Juego**, no cifras directas de NASA).*

| Barra del HUD | Capacidad (`100%`) | Tasa física (`4` humanos / `480 s`) | Tasa en barra del juego (`%/s`) |
|---|---|---|---|
| **Energía Total Base** | `2,000 kWh` *(banco inicial 1 noche)* | `-4.718 kW` (`-6.966 kWh/s` con calefacción) | **`-0.348 %/s`** (`~287 s` autonomía nocturna) |
| **Panel Solar (`25 m²`)** | `+9.87 kW` a `394.7 W/m²` | `+14.569 kWh/s` de día (`0` de noche) | **`+0.729 %/s`** por panel de día |
| **Energía Propia Robot** | `5.42 kWh` *(batería VIPER)* | Salida `~1.2 kWh/viaje`; Taladro `127–300 Wh/m` | **`-22%` por salida** + **`-2.3%` a `-5.5%`** por metro |
| **Recarga (*Descansar*)** | `5.42 kWh` (`6.02 kWh` Base a $\eta=0.9$) | `8 s` de carga completa en Domo | Robot **`+12.50 %/s`** \| Base **`-0.0376 %/s`** *(o `-0.376%/s` en `200 kWh`)* |
| **Oxígeno ($\text{O}_2$)** | `50 kg O₂` *(~14.7 días)* | `-3.40 kg/d` = `-0.2092 kg/s` | **`-0.418 %/s`** (`~239 s` sin OGA; fuga `-0.25%/s` si Escudo $\le 10\%$) |
| **Generador $\text{O}_2$ (OGA)** | Hasta `9.25 kg/d` (`3.29 kW` activo) | `+0.569 kg/s` máx. (pausa `10 s` si Escudo `0%`) | **`+1.138 %/s` O₂** \| **`-0.320 %/s` Agua** \| **`-0.214 %/s` Base** |
| **Agua ($\text{H}_2\text{O}$)** | `200 kg` (`200 L`) | Neta con WRS (`85%` UPA + condens.): `-5.1` a `-9.5 kg/d` | **`-0.157` a `-0.292 %/s`** *(+ consumo OGA)* |
| **Hielo** | `100 kg` hielo (`~1,786 kg` regolito al `5.6%`) | Fusión + WRS (`743 W` activo) | `1 kg hielo -> 1 kg H₂O` (`+0.50%` tanque por `1 kg`) |
| **Escudo** | `100%` = `400 g/cm²` regolito (`~2 m`) | Basal mínimo; 3 niveles SPE CRaTER | Base `-0.015 %/s`; Mod. `-0.45 %/s`, Fuerte `-0.85 %/s`, Sev. `-1.40 %/s` |

---

## 4. Reglas de Honestidad Científica
1. **Separación Luna vs. ISS:** Todo valor de `WRS/UPA`, `OGA` y `CDRA` se cita como dato equivalente de la **ISS**, no como medición directa en la superficie lunar.
2. **Unidades de juego vs. NASA:** Las capacidades de almacenamiento (`2,000 kWh`, `200 kg` de agua, `50 kg` de O₂) y las tasas `%/s` son escalados jugables derivados de los datos reales.
3. **Sin aval ni logos:** Se citan fuentes públicas de la NASA dentro del juego, pero sin usar el logo oficial de NASA ni afirmar respaldo oficial.
