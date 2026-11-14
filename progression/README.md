# `progression/` · Puesto 5 · Guía de Integración y API

**Dueño:** Puesto 5 (Gael · `aax-j`). Solo el dueño cambia estos archivos; los demás piden lo que necesiten en el grupo.  
**Pareja de revisión:** Puesto 2 (Anahi). **Coordinación directa:** Puesto 1 (Ángel) y Puesto 6 (Andrea).

---

## 🧩 Scripts disponibles

| Script | Clase | Responsabilidad |
|---|---|---|
| [`save_manager.gd`](save_manager.gd) | `SaveManager` | Guarda y carga en disco (`user://save_data.json`) estrellas, misiones completadas, mejoras compradas y cartas NASA (*El Legado*). |
| [`mission_manager.gd`](mission_manager.gd) | `MissionManager` | Carga `missions.json`, evalúa eventos y estado del juego, dispara alertas amables y otorga estrellas. |
| [`tech_tree.gd`](tech_tree.gd) | `TechTree` | Carga `upgrades.json`, valida requisitos y estrellas, procesa compras y envía los efectos reales a la simulación. |
| [`test_progression.gd`](test_progression.gd) | *(SceneTree)* | Pruebas automatizadas headless de los 3 módulos. |

---

## 🔌 1. Cómo conectar todo en `core/main.gd` (Puesto 1 · Ángel)

La forma más limpia de unir todo en la escena principal (`scenes/main.tscn` o `core/main.gd`) es añadir los tres nodos (`SaveManager`, `MissionManager`, `TechTree`), compartir el mismo `SaveManager` y conectar las señales hacia **Simulación (Puesto 2)** y **UI (Puesto 6)**.

### Ejemplo listo para copiar en `core/main.gd`

```gdscript
extends Node

const SaveManagerScript := preload("res://progression/save_manager.gd")
const MissionManagerScript := preload("res://progression/mission_manager.gd")
const TechTreeScript := preload("res://progression/tech_tree.gd")

var save_manager: Node
var mission_manager: Node
var tech_tree: Node
var modo_actual: String = "cadete"

func _ready() -> void:
	# 1. Crear e inicializar los módulos de progresión
	save_manager = SaveManagerScript.new()
	mission_manager = MissionManagerScript.new()
	tech_tree = TechTreeScript.new()

	# Inyectar el mismo SaveManager antes de añadirlos al árbol
	mission_manager.set_save_manager(save_manager)
	tech_tree.set_save_manager(save_manager)

	add_child(save_manager)
	add_child(mission_manager)
	add_child(tech_tree)

	# 2. Conectar señales hacia UI (Puesto 6) y Simulación (Puesto 2)
	mission_manager.mision_activa_cambiada.connect(_on_mision_activa_cambiada)
	mission_manager.progreso_objetivo_actualizado.connect(_on_progreso_mision)
	mission_manager.mision_completada.connect(_on_mision_completada)
	mission_manager.mision_fallida.connect(_on_mision_fallida)
	mission_manager.simulacro_supertormenta_solicitado.connect(_on_simulacro_m14)

	tech_tree.efecto_simulacion_aplicado.connect(_on_aplicar_efecto_simulacion)
	tech_tree.estrellas_actualizadas.connect(_on_estrellas_actualizadas)
	tech_tree.mejora_desbloqueada.connect(_on_mejora_desbloqueada)

	# 3. Aplicar mejoras que el jugador ya tenía guardadas y arrancar misión
	modo_actual = save_manager.obtener_modo_preferido()
	mission_manager.establecer_modo_juego(modo_actual)
	tech_tree.aplicar_todas_las_mejoras_guardadas(modo_actual)
	mission_manager.notificar_evento("partida_iniciada")

func _process(delta: float) -> void:
	# En cada tick, pasarle a MissionManager el diccionario actual de la simulación (P2)
	var estado_base: Dictionary = simulacion.obtener_estado_actual()
	mission_manager.evaluar_estado_simulacion(estado_base, delta)
```

---

## 🎨 2. Cómo se conecta la UI (`ui/` · Puesto 6 · Andrea)

La interfaz **no necesita leer JSON manualmente**. Usa estas señales para reaccionar y estas funciones para consultar o comprar.

### A. Señales que la UI debe escuchar

| Señal (Emisor) | Parámetros | Para qué sirve en la UI |
|---|---|---|
| `mision_activa_cambiada` *(MissionManager)* | `(mision_data: Dictionary)` | Actualiza el título (`mision_data["mision"]`) y lista de objetivos (`mision_data["objetivo"]`). |
| `progreso_objetivo_actualizado` *(MissionManager)* | `(id_mision: String, triggers_cumplidos: Array, total_triggers: int)` | Muestra cuántas metas lleva el niño (ej. `2 / 3`). |
| `mision_completada` *(MissionManager)* | `(id_mision: String, estrellas: int, carta_nasa: Dictionary)` | Abre la pantalla de celebración y muestra la carta NASA (`titulo`, `dato`, `fuente`). |
| `mision_fallida` *(MissionManager)* | `(id_mision: String, reporte_fallo: String)` | Muestra el globo de consejo amable de la Vicuña con `reporte_fallo`. |
| `estrellas_actualizadas` *(TechTree)* | `(total_estrellas: int)` | Actualiza el contador de estrellas disponibles en el HUD y en el Árbol. |
| `mejora_desbloqueada` *(TechTree)* | `(id_mejora: String, rama: String, nivel: int)` | Marca el nodo del árbol como comprado (verde/activo) y desbloquea visualmente el siguiente nivel. |
| `compra_rechazada` *(TechTree)* | `(id_mejora: String, motivo: String)` | Avisa por qué no se pudo comprar (`"estrellas_insuficientes"`, `"falta_requisito:..."`, `"ya_comprada"`). |

### B. Funciones que la UI debe llamar

* **Mostrar misión actual al abrir el HUD:**
  ```gdscript
  var mision := mission_manager.obtener_mision_activa()
  # mision["mision"] -> Título | mision["objetivo"] -> Array de pasos
  ```
* **Dibujar el Árbol de Habilidades:**
  ```gdscript
  var ramas := tech_tree.obtener_ramas() # Array con las 4 ramas y sus 3 mejoras c/u
  var estrellas := tech_tree.obtener_estrellas_disponibles()
  for rama in ramas:
      for mejora in rama["mejoras"]:
          var comprada := tech_tree.esta_comprada(mejora["id"])
          var check := tech_tree.puede_comprar(mejora["id"]) # {"ok": bool, "motivo": String}
  ```
* **Al presionar el botón de comprar una mejora:**
  ```gdscript
  var exito := tech_tree.comprar_mejora(id_mejora, modo_actual)
  # Si devuelve true, se disparan automáticamente mejora_desbloqueada,
  # efecto_simulacion_aplicado y estrellas_actualizadas.
  ```
* **Reiniciar partida/progreso desde menú de opciones:**
  ```gdscript
  save_manager.reiniciar_legado()
  ```

---

## 🔬 3. Cómo se conecta Simulación e Interacción (Puesto 2 · Anahi y Puesto 4 · Nicolás)

### A. Eventos puntuales que deben enviar a `mission_manager.notificar_evento(nombre, datos)`

Llama a `mission_manager.notificar_evento(...)` apenas ocurra cada acción del jugador o de la simulación:

| Nombre del evento (`nombre_evento`) | `datos` recomendados | Quién lo emite |
|---|---|---|
| `"partida_iniciada"` | `{}` | P1 (Core) |
| `"estructura_construida"` | `{"id_estructura": "panel_solar" \| "procesador_hielo" \| "generador_oxigeno" \| "jardin", "total_paneles": int}` | P4 / P2 |
| `"viaje_hielo_iniciado"` | `{}` | P4 |
| `"viaje_hielo_completado"` | `{"en_alerta_nube": bool}` | P2 / P4 |
| `"hielo_procesado"` | `{"es_noche": bool}` | P2 |
| `"reparar_escudo_iniciado"` | `{}` | P4 |
| `"escudo_reparado"` | `{}` | P2 |
| `"advertencia_nube_iniciada"` | `{"en_viaje_hielo": bool}` | P2 |
| `"nube_impacto"` | `{"minuto_aprox": int, "escudo_restante": float}` | P2 |
| `"nube_superada"` *(o `"nube_finalizada"`)* | `{}` | P2 |
| `"tormenta_maxima_resistida"` | `{}` *(para completar Misión 14 sin obligar a romper el escudo)* | P2 |

### B. Diccionario esperado en `mission_manager.evaluar_estado_simulacion(estado, delta)`
Las llaves coinciden con [diccionario/variables_sistema.json](../../diccionario/variables_sistema.json):
```gdscript
{
	"energia": float,
	"hielo": int,
	"agua": float,
	"oxigeno": float,
	"vida": float,
	"escudo": float,
	"es_dia": bool,
	"alerta_nube": bool,
	"nube_activa": bool,
	"en_viaje_hielo": bool,
	"paneles_instalados": int,
	"procesador_instalado": bool,
	"generador_instalado": bool,
	"jardin_instalado": bool,
	"generador_pausado": bool,
	"tiempo_juego": float,
	"tiempo_ciclo_solar": float
}
```

### C. Efectos que `tech_tree` envía a Puesto 2 (`efecto_simulacion_aplicado(tipo_efecto, datos_efecto)`)

| `tipo_efecto` | Contenido exacto de `datos_efecto` | Qué actualiza Puesto 2 |
|---|---|---|
| `"limite_estructura"` | `{"id_mejora", "max_paneles": 3}` | Sube tope de paneles de 2 a 3. |
| `"energia_maxima"` | `{"id_mejora", "energia_maxima": 150.0}` | Sube tope de energía de 100 a 150. |
| `"produccion_solar"` | `{"id_mejora", "produccion_por_s": 0.75, "multiplicador": 1.25}` | Panel solar pasa de `0.6` a `0.75/s`. |
| `"velocidad_procesador"` | `{"id_mejora", "tiempo_proceso_s": 3.0}` | Procesador baja de `5s` a `3s` por hielo. |
| `"consumo_oxigeno"` | `{"id_mejora", "multiplicador_consumo": 0.75, "ahorro_pct": 25}` | Generador gasta `-25%` de energía y agua. |
| `"desbloqueo_jardin"` | `{"id_mejora", "jardin_desbloqueado": true, "regeneracion_vida_s": 0.4}` | Habilita construir Jardín y cura doble. |
| `"costo_reparacion"` | `{"id_mejora", "costo_cadete": 15, "costo_ingeniero": 22, "valor_activo": int}` | Reparar escudo cuesta `15` (`22` Ing.). |
| `"resistencia_nube"` | `{"id_mejora", "dano_cadete": 22, "dano_ingeniero": 30, "valor_activo": int}` | Golpe nube baja a `22` (`30` Ing.). |
| `"tiempo_alerta"` | `{"id_mejora", "aviso_segundos": 40, "tiempo_reparacion_s": 2}` | Aviso solar `40s` y reparar tarda `2s`. |
| `"herramienta_hielo"` | `{"id_mejora", "herramienta_nivel": 2..4, "hielo_por_viaje": 4\|7\|10, "vida_perdida_cadete": 8\|6\|3, "vida_perdida_ingeniero": 12\|9\|5, "vida_perdida_activa": float}` | Cambia herramienta activa y desgaste. |

---

## 📚 4. Referencia Rápida de Todas las Funciones Públicas

### `SaveManager` (`save_manager.gd`)
* `cargar_progreso() -> Dictionary` — Lee `user://save_data.json` (o crea uno nuevo si no existe).
* `guardar_progreso() -> bool` — Guarda el estado actual en disco.
* `registrar_mision_completada(id_mision: String, puntos: int, id_carta: String = "") -> bool` — Guarda misión y suma estrellas solo la primera vez.
* `registrar_mejora_comprada(id_mejora: String, costo: int, id_carta: String = "") -> bool` — Descuenta estrellas y guarda la mejora.
* `reiniciar_legado() -> void` — Borra progreso y vuelve a `0` estrellas.
* `obtener_estrellas_disponibles() -> int` / `obtener_estrellas_totales() -> int`
* `esta_mision_completada(id_mision: String) -> bool` / `esta_mejora_comprada(id_mejora: String) -> bool`
* `obtener_misiones_completadas() -> Array[String]` / `obtener_mejoras_compradas() -> Array[String]` / `obtener_cartas_desbloqueadas() -> Array[String]`
* `obtener_modo_preferido() -> String` / `establecer_modo_preferido(modo: String) -> void`
* `obtener_datos_completos() -> Dictionary`

### `MissionManager` (`mission_manager.gd`)
* `set_save_manager(manager: Node) -> void` — Vincula el `SaveManager` compartido.
* `establecer_modo_juego(modo: String) -> void` — `"cadete"` o `"ingeniero"`.
* `cargar_misiones(ruta: String = "res://data/missions/missions.json") -> bool`
* `obtener_mision_activa() -> Dictionary` / `obtener_todas_las_misiones() -> Array` / `obtener_triggers_cumplidos() -> Array`
* `activar_mision(id_mision: String) -> bool` — Activa una misión específica (para `mision_14` emite también `simulacro_supertormenta_solicitado`).
* `notificar_evento(nombre_evento: String, datos: Dictionary = {}) -> void` — Registra acciones puntuales del jugador/simulación.
* `evaluar_estado_simulacion(estado: Dictionary, delta_s: float = 0.0) -> void` — Evalúa metas continuas y fallos amables.

### `TechTree` (`tech_tree.gd`)
* `set_save_manager(manager: Node) -> void` — Vincula el `SaveManager` compartido.
* `cargar_arbol(ruta: String = "res://data/missions/upgrades.json") -> bool`
* `obtener_ramas() -> Array` / `obtener_mejora(id_mejora: String) -> Dictionary`
* `obtener_estrellas_disponibles() -> int` / `tiene_estrellas(costo: int) -> bool` / `esta_comprada(id_mejora: String) -> bool`
* `puede_comprar(id_mejora: String) -> Dictionary` — Devuelve `{"ok": bool, "motivo": String}`.
* `comprar_mejora(id_mejora: String, modo_juego: String = "cadete") -> bool` — Valida, descuenta y aplica efecto.
* `aplicar_todas_las_mejoras_guardadas(modo_juego: String = "cadete") -> void` — Reaplica al iniciar partida todas las mejoras del Legado.

---

## 🧪 5. Cómo correr las pruebas automáticas
Desde la carpeta `chullasolution-space-apps-2026/`:
```powershell
..\godot_tools\Godot_v4.7.2-stable_win64_console.exe --headless --script "res://progression/test_progression.gd"
```

## ✅ Antes de pedir un Pull Request
- El juego abre con F5.
- Anotaste en [docs/registro/puesto-5.md](../docs/registro/puesto-5.md) lo que usaste de IA, de terceros o de NASA.
