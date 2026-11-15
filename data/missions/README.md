# `data/missions/` · Puesto 5 · Datos de Misiones y Mejoras

**Dueño:** Puesto 5 (Gael · `aax-j`). Solo el dueño cambia estos archivos; los demás piden lo que necesiten en el grupo.  
**Pareja de revisión:** Puesto 2 (Anahi).

---

## 📦 Archivos disponibles

| Archivo | Ruta en Godot | Contenido |
|---|---|---|
| [`missions.json`](missions.json) | `res://data/missions/missions.json` | Campaña oficial de **16 misiones** (`mision_01` a `mision_16`, 24★ totales). |
| [`upgrades.json`](upgrades.json) | `res://data/missions/upgrades.json` | Árbol de **4 ramas** (`energia`, `soporte_vital`, `escudo`, `herramientas`) y **12 mejoras** (costos `1★`, `2★`, `3★`). |

> [!TIP]
> **Para UI (`ui/`) y Core (`core/`):** No necesitas abrir ni parsear estos JSON manualmente. Los scripts de [`progression/`](../progression/README.md) ya los cargan al iniciar y entregan todos los datos listos como `Dictionary` y `Array` mediante sus funciones y señales.

---

## 🗂️ Estructura de los datos (para mostrar en UI)

### 1. Estructura de cada misión en `missions.json`
Cuando la UI llama a `mission_manager.obtener_mision_activa()` o recibe la señal `mision_activa_cambiada(mision_data)`, recibe un `Dictionary` con estas llaves:

```json
{
  "id": "mision_01",
  "mision": "Energía Vital",
  "dificultad": ["cadete", "ingeniero"],
  "puntos": { "cadete": 1, "ingeniero": 1 },
  "trigger": ["partida_iniciada", "panel_solar_construido", "energia_mayor_70"],
  "objetivo": [
	"Elegir una casilla libre cerca del domo y construir 1 panel solar",
    "Aprovechar la luz del día para subir la energía por encima de 70 puntos"
  ],
  "condicion_fallo": ["energia_cero", "inaccion_prolongada_amanecer"],
  "reporte_fallo": "Texto amable de la Vicuña explicando qué pasó...",
  "desbloquea": { "mision_siguiente": "mision_02" },
  "carta_nasa": {
	"titulo": "Energía Solar en la Luna",
	"dato": "Explicación científica adaptada para niños...",
	"fuente": "NASA Glenn Research Center / Sistemas de Energía Espacial"
  }
}
```

### 2. Estructura del árbol en `upgrades.json`
Cuando la UI llama a `tech_tree.obtener_ramas()`, recibe un `Array` de 4 ramas. Cada rama contiene:
* `id`: `"energia"`, `"soporte_vital"`, `"escudo"`, `"herramientas"`
* `nombre`: título visible de la rama (ej. `"Rama Energía ⚡"`)
* `descripcion`: explicación breve
* `mejoras`: `Array` de 3 niveles (`1`, `2`, `3`), cada uno con:
  * `id`: identificador único (ej. `"panel_extra"`)
  * `nivel`: `1`, `2` o `3`
  * `nombre`: nombre visible (ej. `"Panel Solar Extra"`)
  * `costo`: `1`, `2` o `3` estrellas
  * `requisito`: `null` o el `id` de la mejora previa requerida (ej. `"panel_extra"`)
  * `efecto.descripcion`: texto amigable para mostrar al niño en el botón de compra
  * `carta_nasa`: `{ "titulo", "dato", "fuente" }`

---

## 🚫 Qué NO va aquí
- Código `.gd`: toda la lógica va en `progression/`.
- Números de simulación inventados sin rotular como **unidades de juego**.

## ✅ Antes de pedir un Pull Request
- El juego abre con F5.
- Anotaste en [docs/registro/puesto-5.md](../../docs/registro/puesto-5.md) lo que usaste de IA, de terceros o de NASA.
