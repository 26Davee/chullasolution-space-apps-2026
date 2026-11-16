# Cálculos del Sistema de Simulación (Base NASA -> Escala del Juego)

> Todos los cálculos físicos parten estrictamente de [DATOS_NASA.md](DATOS_NASA.md).
> **Reglas vigentes del juego:**
> - **Sin `vida`:** ni los humanos ni el robot usan barra de vida.
> - **Dos energías separadas:** barra propia de **Energía del Robot** + barra de **Energía Total de la Base**.
> - **Recarga del Robot:** al acercarse al Domo y pulsar **Descansar**, la Base transfiere energía al Robot (`Energía Base` baja, `Energía Robot` sube).
> - **Tripulación fija en el Domo:** **`4` humanos**.
> - **Ciclo temporal:** **`480 s` = `29.53 días` terrestres** (`240 s` luz + `240 s` noche), con rollover calendario (`30 días -> +1 mes`, `12 meses -> +1 año`).

---

## 1. Conversión de Tiempo (Ya implementada en el motor)

$$\Delta t_{\text{sim}} = \frac{29.53\text{ días}}{480\text{ s}} = \mathbf{0.061521\text{ días}/\text{s}} = \mathbf{1.4765\text{ horas}/\text{s}}$$

- **$1\text{ día terrestre simulado}$** $= \frac{480}{29.53} = \mathbf{16.255\text{ s reales}}$
- **$1\text{ hora simulada}$** $= \mathbf{0.6773\text{ s reales}}$
- **Medio ciclo (día de luz o noche lunar, `240 s` reales)** $= \mathbf{14.765\text{ días}} = \mathbf{354.36\text{ h}}$

---

## 2. Balance de Agua ($\text{H}_2\text{O}$) y Oxígeno ($\text{O}_2$) para 4 Humanos

### 2.1 Oxígeno ($\text{O}_2$)
- Demanda metabólica (`BVAD`: $0.84 - 0.89\text{ kg/persona}\cdot\text{día}$, nominal $0.85$):
  $$\dot{m}_{\text{O}_2,\text{ 4 humanos}} = 4 \times 0.85 = \mathbf{3.40\text{ kg }\text{O}_2/\text{día}} \quad (\text{rango } 3.36 - 3.56\text{ kg/día})$$
- Tasa literal en escala temporal del juego:
  $$\dot{m}_{\text{O}_2,\text{ juego}} = 3.40 \times 0.061521 = \mathbf{0.2092\text{ kg }\text{O}_2/\text{s}}$$
  - Consumo en toda una noche lunar (`240 s` = `14.765 días`): **$\mathbf{50.20\text{ kg O}_2}$** (`99.22 – 105.13 kg` por ciclo completo de `480 s`).
- Producción con **OGA** (`ISS`, máx. $9.25\text{ kg/día}$):
  - Ciclo de trabajo necesario para empatar a 4 humanos: $\frac{3.40}{9.25} = \mathbf{36.8\%}$ del tiempo activo ($\approx 8.8\text{ h/día}$).
  - Agua consumida por electrólisis ($\frac{18.015}{16.000} = 1.1259\text{ kg H}_2\text{O}/\text{kg O}_2$):
    $$\dot{m}_{\text{H}_2\text{O}\to\text{O}_2} = 3.40 \times 1.1259 = \mathbf{3.828\text{ kg H}_2\text{O}/\text{día}} = \mathbf{0.2355\text{ kg/s}}$$
    En `240 s` de noche lunar: **$\mathbf{56.52\text{ kg H}_2\text{O}}$** solo para generar $\text{O}_2$.

### 2.2 Agua ($\text{H}_2\text{O}$) y Recuperación **WRS / UPA**
- **Demanda potable mínima sin higiene** (`BVAD`: $2.50\text{ kg/persona}\cdot\text{día}$ bebida + comida):
  $$4 \times 2.50 = \mathbf{10.00\text{ kg H}_2\text{O}/\text{día}} = \mathbf{0.6152\text{ kg/s}} \quad (\mathbf{147.65\text{ kg}} \text{ por noche})$$
- **Carga al UPA** (`Agua.pdf`: $9\text{ kg/día}$ para 6 tripulantes $\Rightarrow 1.50\text{ kg/persona}\cdot\text{día}$):
  $$4 \times 1.50 = \mathbf{6.00\text{ kg/día}}$$
- **Agua recuperada por UPA al $85\%$ mínimo** (`Agua.pdf`):
  $$6.00 \times 0.85 = \mathbf{5.10\text{ kg H}_2\text{O}/\text{día}} = \mathbf{0.3138\text{ kg/s}} \quad (\mathbf{75.30\text{ kg}} \text{ por noche})$$
- **Condensado de humedad humana** (`BVAD`: respiración + sudor = $2.28 - 2.95\text{ kg/persona}\cdot\text{día}$):
  $$4 \times 2.28 = \mathbf{9.12\text{ kg/día}} \quad (\text{hasta } 11.80\text{ kg/día})$$
  *Nota:* En lazo cerrado tipo ISS (`WRS` recuperando $85\%$ de orina + $\sim 100\%$ del condensado de cabina, donde `Agua.pdf` reportó $44\%$ destilado + $56\%$ condensado), gran parte del agua de bebida vuelve por condensado + UPA; la **pérdida neta inevitable** proviene principalmente de la **electrólisis de $\text{O}_2$ ($3.83\text{ kg/d}$ sin Sabatier)** + agua fecal ($0.40\text{ kg/d}$) + margen residual de salmuera ($0.90\text{ kg/d}$ UPA) + higiene no reciclada: **$\approx 5.1 - 9.5\text{ kg H}_2\text{O}/\text{día}$ de reposición real** ($\mathbf{0.31 - 0.59\text{ kg/s}}$ en el juego).

### 2.3 Módulo Opcional: Jardín (*NASA Veggie / BPC*)
- **Referencia:** `10–30+ g O₂/m²·día`; `20–25 m²` cubren a `1` humano (`~0.85 kg O₂/d`).
- Si un módulo **Jardín** en el juego representa p. ej. **`10 m²`** de cultivo intensivo a `30 g O₂/m²·día`:
  - Aporte $\text{O}_2$: **$0.30\text{ kg O}_2/\text{día}$** ($\approx \mathbf{8.8\%}$ del consumo de los 4 humanos, reduce la carga del OGA).
  - Costo eléctrico LED (`150–400 W/m²`, tomando $250\text{ W/m}^2$): **`2.50 kW`** mientras está encendido.

---

## 3. Energía Total de la Base vs. Paneles Solares

### 3.1 Demanda eléctrica continua de la Base (4 Humanos)
Sumando los subsistemas medidos / documentados en `DATOS_NASA.md`:
1. **WRS (Procesador de Agua, `Agua.pdf`):** `0.743 kW` procesando (`0.297 kW` en espera).
2. **OGA (Generador de $\text{O}_2$ al `36.8%` activo / `63.2%` espera):**
   $$P_{\text{OGA, prom}} = (3.2865 \times 0.3676) + (0.382 \times 0.6324) = \mathbf{1.450\text{ kW}} \quad (\mathbf{34.79\text{ kWh/día}})$$
3. **Remoción de $\text{CO}_2$ (`4BCO2` para 4 humanos):** **`0.975 kW`** promedio (`0.559 kW` con CDRA clásico).
   - **Subtotal ECLSS puro (`WRS + OGA + 4BCO2`):** **$\mathbf{3.168\text{ kW}}$** $\Rightarrow$ **$\mathbf{76.03\text{ kWh/día}}$** ($\mathbf{1,122.6\text{ kWh}}$ por noche lunar de `354.36 h`).
4. **Calefacción nocturna / soporte térmico mínimo (`Artemis LSH`):** **`+1.550 kW`**
   - **Mínimo vital nocturno (`ECLSS + calefacción`):** **$\mathbf{4.718\text{ kW}}$** $\Rightarrow$ **$\mathbf{113.23\text{ kWh/día}}$** ($\mathbf{1,671.9\text{ kWh}}$ por noche lunar).
5. **Techo de referencia Artemis LSH en operación tripulada plena** (con cargas científicas, iluminación, aviónica y márgenes): hasta **`20 kW`** (`480 kWh/día` $\Rightarrow$ `7,087 kWh/noche`).

### 3.2 Generación por Panel Solar
$$P_{\text{específica}} = 1,361\text{ W/m}^2 \times 0.29 = \mathbf{394.7\text{ W/m}^2} = \mathbf{0.3947\text{ kW/m}^2}$$
- Cada **`25 m²`** de panel solar instalado entrega **$\mathbf{9.87\text{ kW}}$** continuos en fase de luz (`240 s`):
  - En escala juego: **$\mathbf{14.569\text{ kWh/s}}$** durante los `240 s` de día ($\mathbf{3,497\text{ kWh}}$ acumulados por día lunar).
  - *Regla energética:* Un solo módulo solar de `25 m²` (`9.87 kW`) cubre la carga mínima vital de `4.72 kW` y deja un excedente de `5.15 kW` (`+0.7285 %/s` bruto sobre `2,000 kWh`) para recargar la base con comodidad; con `2` paneles se alcanza superávit holgado para OGA, jardín e imprevistos nocturnos.

---

## 4. Energía Propia del Robot, Taladro, Hielo y Recarga en Domo

### 4.1 Batería Propia del Robot (`VIPER`)
- **Capacidad total (`100%` barra del Robot):** **`5,420 Wh` = `5.42 kWh`**.
- **Desplazamiento:** potencia pico **`300 W`** (`0.30 kW`) en pendiente/regolito (`~18.07 h` continuas de marcha máxima con batería llena).
  - *Factor de escala jugable (Constante de Diseño):* En tiempo literal ($1\text{ s} = 1.4765\text{ h}$), un viaje de $10\text{ s}$ simularía $14.77\text{ h}$. Si definimos un viaje ida y vuelta Base $\leftrightarrow$ Cráter como una salida de exploración equivalente a **$4\text{ h}$ reales de conducción** ($\mathbf{1.20\text{ kWh}}$ a $300\text{ W}$), cada excursión consume **$\mathbf{22.1\%}$** de la batería del robot (`1.20 / 5.42`).

### 4.2 Taladro (`TRIDENT` / `Apollo ALSD`) y Extracción de Hielo (`LCROSS`)
- **Energía de perforación de `1 m` (`TRIDENT` $< 1\text{ h}$):**
  - Promedio barrena + calefactor (`87 W + 40 W = 127 W` por `1 h`): **`127 Wh`** (**`2.34%`** de la batería de `5,420 Wh`).
  - Pico de roca/hielo duro (`300 W` por `1 h`): **`300 Wh`** (**`5.54%`** de la batería de `5,420 Wh`).
- **Rendimiento de hielo por masa de regolito excavada (`LCROSS 5.6% wt`):**
  $$\text{Hielo}_{\text{kg}} = \text{Regolito}_{\text{kg}} \times 0.056$$
  - `50 kg` regolito $\rightarrow$ **`2.80 kg` hielo** | `100 kg` $\rightarrow$ **`5.60 kg` hielo** | `200 kg` $\rightarrow$ **`11.20 kg` hielo**.
- **Comparativa de herramientas del juego (propuesta anclada a NASA):**
  - **Pala / Pico manual o brazo ligero:** mayor tiempo de animación y menor masa/s (`regolito suelto`, baja profundidad), mayor tiempo de exposición del robot.
  - **Taladro ligero (`~87 W`):** velocidad intermedia, consumo bajo (`~2.3%` batería por ciclo).
  - **Taladro rotativo-percusivo tipo TRIDENT (`~300 W`):** menor tiempo por extracción en permafrost (`2–5 cm/min` ALSD / `<1 h` por `1 m` TRIDENT), consumo **`~5.5%`** por ciclo.
  - *Importante:* Por jugabilidad, el **tiempo visual** de excavación (`3 – 12 s` según herramienta) no usa `1 s = 1.48 h` literal (que sería `< 0.7 s`), mientras que la **energía descontada (`Wh`) sí respeta los `127–300 Wh` reales por metro perforado**.

### 4.3 Recarga en el Domo (*Descansar*: `Base -> Robot`)
$$\Delta E_{\text{Robot}} = +\text{carga} \quad \Longleftrightarrow \quad \Delta E_{\text{Base}} = -\frac{\Delta E_{\text{Robot}}}{\eta_{\text{carga}}}$$
- Si la batería de la Base se dimensiona para sobrevivir **1 noche lunar mínima (`2,000 kWh` = `100%` Barra Base)** y $\eta_{\text{carga}} = 0.90$:
  - Recargar el Robot del **$0\% \to 100\%$** (`5.42 kWh`) toma de la Base $\frac{5.42}{0.90} = \mathbf{6.02\text{ kWh}}$, es decir **$\mathbf{0.301\%}$** de la energía de la Base.
  - Si se quiere que recargar al robot sea una decisión más visible en una base pequeña (p. ej. banco modular inicial de **`200 kWh`** mientras construyes infraestructura), una carga completa del robot gasta **$\mathbf{3.01\%}$** de la energía de la Base.
- **Tasa sugerida de carga en tiempo real al pulsar *Descansar*:** si `0% -> 100%` del robot tarda **`8 s`** reales cerca del Domo, el robot recupera **$+12.5\%/\text{s}$** (`+0.678 kWh/s` reales), mientras la Base baja **`-0.0376%/s`** (en banco `2,000 kWh`) o **`-0.376%/s`** (en banco `200 kWh`).

---

## 5. Radiación Lunar y Degradación / Protección del Escudo

Con los datos reales de **LRO CRaTER-D1D2** (`RadLab API`):
- **Fondo tranquilo basal (GCR):** `9.13 μGy/h` órbita (`~13.29 μGy/h` superficie = `~0.319 mGy/día`).
- **Multiplicadores reales observados en tormentas SPE (`LRO CRaTER-D1D2`):**
  - Tormenta moderada/media (ref. Mayo 2024): pico **`3,151.75 μGy/h`** $\Rightarrow$ **`345×`** basal.
  - Tormenta fuerte (ref. Septiembre 2017): pico **`22,968.75 μGy/h`** $\Rightarrow$ **`2,515×`** basal.
  - Tormenta severa / extrema (ref. Enero 2012 M8.7 — análoga en categoría a Enero 2026 S4 `36,976 pfu`): pico **`61,829.17 μGy/h`** $\Rightarrow$ **`6,770×`** basal.
- **Modelo físico para `Escudo` (`0–100%`):**
  - `100% Escudo` representa la cobertura nominal de **$\ge 400\text{ g/cm}^2$ de regolito** ($\approx 2.0 - 2.66\text{ m}$ de espesor a $1.5 - 2.0\text{ g/cm}^3$) que protege al Domo frente a GCR y SPE.
  - **Degradación física:** durante **GCR normal** el desgaste por micrometeoritos/erosión térmica es casi despreciable (`~0.01 - 0.03%/s` para mantener gameplay); durante una **tormenta SPE**, si el juego usa factor de daño normalizado al logaritmo del flujo ($F = \log_{10}(\text{tasa}/\text{basal})$):
    - Basal ($1\times$): $F = 0$ (sin daño por radiación, solo mantenimiento menor).
    - Tormenta moderada ($345\times$): $F = \log_{10}(345) \approx \mathbf{2.54}$
    - Tormenta fuerte ($2,515\times$): $F = \log_{10}(2,515) \approx \mathbf{3.40}$
    - Tormenta extrema ($6,770\times$): $F = \log_{10}(6,770) \approx \mathbf{3.83}$
  - Así evitamos que un pico real de `6,770×` destruya el escudo en `0.01 s`, preservando exactamente la proporción física de severidad entre eventos reales de la NASA.

---

## 6. Tabla Maestra Lista para Validación de Barras (`0 – 100%`)

> **Separación explícita:** Los valores físicos vienen de [DATOS_NASA.md](DATOS_NASA.md); las capacidades de tanque/banco son **Constantes de Diseño del Juego** elegidas para sostener al menos `1` noche lunar completa (`240 s` = `14.765 días`) dando margen al jugador.

| Barra del HUD | Ancla física (`100%` = Capacidad) | Tasa física (`4` humanos / `480 s = 29.53 d`) | Tasa en barra del juego (`%/s`) |
|---|---|---|---|
| **Energía Total Base** | **`2,000 kWh`** *(banco base inicial para 1 noche)* | `-4.718 kW` (`-6.966 kWh/s` con calefacción) | **`-0.348 %/s`** (`~287 s` autonomía nocturna) |
| **Panel Solar (`25 m²`)** | `+9.87 kW` a `394.7 W/m²` (`29%` III-V) | `+14.569 kWh/s` de día (`0` de noche) | **`+0.729 %/s`** por panel de día *(1 panel = supera consumo base con margen)* |
| **Energía Propia Robot** | **`5.42 kWh`** *(batería VIPER real)* | Salida/marcha (`~1.2 kWh/viaje`), Taladro (`127–300 Wh/m`) | **`-22%` por salida** + **`-2.3%` a `-5.5%`** por metro perforado |
| **Recarga (*Descansar*)** | Transfiere `5.42 kWh` (`6.02 kWh` Base a $\eta=0.9$) | `8 s` de carga completa en el Domo | Robot **`+12.50 %/s`** \| Base **`-0.0376 %/s`** *(o `-0.376%/s` en banco 200 kWh)* |
| **Oxígeno ($\text{O}_2$)** | **`50 kg O₂`** *(~14.7 días / 1 fase lunar)* | `-3.40 kg/d` = `-0.2092 kg/s` | **`-0.418 %/s`** (`~239 s` sin OGA; fuga extra `-0.25%/s` si Escudo $\le 10\%$) |
| **Generador $\text{O}_2$ (OGA)** | Hasta `9.25 kg/d` (`3.29 kW` activo) | `+9.25 kg/d` máx. = `+0.569 kg/s` (consume H₂O y kW; pausa `10 s` si Escudo `0%`) | **`+1.138 %/s` $\text{O}_2$** \| **`-0.320 %/s` Agua** \| **`-0.214 %/s` Base** |
| **Agua ($\text{H}_2\text{O}$)** | **`200 kg` (`200 L`)** *(potable reserva)* | Neta con WRS (`85%` UPA + condensado): **`-5.1` a `-9.5 kg/d`** | **`-0.157` a `-0.292 %/s`** *(más consumo OGA cuando produce $\text{O}_2$)* |
| **Hielo** | **`100 kg` hielo** (`~1,786 kg` regolito al `5.6%`) | Procesado por fusión + WRS (`743 W` activo) | Conversión **`1 kg hielo -> 1 kg H₂O`** (`+0.50 %` tanque `200 kg` por cada `1 kg` hielo) |
| **Escudo** | **`100%` = `400 g/cm²` regolito** (`~2 m`) | Desgaste basal mínimo; 3 niveles de SPE CRaTER (`345×`, `2,515×`, `6,770×`) | Base **`-0.015 %/s`**; Moderada **`-0.45 %/s`** (`~11%`), Fuerte **`-0.85 %/s`** (`~21%`), Severa **`-1.40 %/s`** (`~35%`) |

---

## 7. Constantes de diseño (valores de juego)

1. **Tamaño inicial del banco de batería de la Base:** elegir si arrancamos en **`2,000 kWh`** (realista para noche lunar, recarga al robot gasta `0.30%`) o un banco inicial más chico como **`500 kWh`** (recarga al robot gasta **`1.20%`**, haciendo la gestión energética más tensa al inicio hasta construir más baterías/paneles).
2. **Factor de balance educativo:** decidir si dejamos estas tasas literales (`-0.35%/s` Base de noche, `-0.21%/s` $\text{O}_2$) o aplicamos un factor suave (p. ej. `0.75×`) para la dificultad **Cadete** vs **Ingeniero**.
