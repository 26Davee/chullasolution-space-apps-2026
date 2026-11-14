# ChullaSolution · NASA Space Apps Challenge 2026 (Riobamba)

**Challenge:** *Build a Junior Astronaut Mission Trainer* — a game that teaches children aged 7–12 something true about how astronauts survive.

**Team:** ChullaSolution, six students of ESPOCH (Riobamba, Ecuador). Student project made for the local Riobamba event of NASA Space Apps Challenge 2026. It is not endorsed by NASA and does not use NASA logos.

**Status:** the game is built during the hackathon (Saturday 14 – Sunday 15 November 2026). Game code, art and data are created by the team inside this repository from the opening of the event, Saturday 14 November at 09:00 (Ecuador time). Everything we use that is not ours (engine, fonts, sounds, NASA data) is listed with its license or source in `docs/`. Everything made with AI help is listed in `docs/AI_USE.md`.

**Game:** *Inti Killa* (Kichwa for "Sun Moon"): a low-poly lunar outpost game guided by an astronaut vicuña.

**Play it:** link added by the integration role when the first web build opens.

---

## En español

Repositorio del equipo **ChullaSolution**. Aquí vive todo el trabajo del hackatón: un solo proyecto de Godot, seis personas, cada una dueña de sus carpetas.

### Empieza por aquí (3 pasos)

1. **Busca tu número de puesto** en la tabla de abajo. Tus carpetas son las que tienen tu número.
2. **Abre el `README.md` de tus carpetas.** Dice qué va ahí, qué no y cuál es tu primera tarea.
3. **Antes de empezar cada bloque, baja lo último** (guía abajo) y trabaja siempre en tu rama.

| Si quieres saber… | Lee |
|---|---|
| **Cómo es el juego** (diseño de Inti Killa) | [`docs/DISENO_JUEGO.md`](docs/DISENO_JUEGO.md) |
| **Qué carpeta es tuya y cuáles no debes tocar** | [`docs/QUIEN_TOCA_QUE.md`](docs/QUIEN_TOCA_QUE.md) |
| **«Quiero hacer X, ¿dónde va?»** | La tabla «Quiero… → va en…» de [`docs/QUIEN_TOCA_QUE.md`](docs/QUIEN_TOCA_QUE.md) |
| **Cómo subir y bajar cambios** (paso a paso) | [`docs/GUIA_GIT.md`](docs/GUIA_GIT.md) |
| **Reglas de trabajo** (ramas, Pull Request, revisión) | [`CONTRIBUTING.md`](CONTRIBUTING.md) |
| **Qué datos se pasan entre puestos** | [`docs/CONTRATOS.md`](docs/CONTRATOS.md) |

### El mapa del proyecto

`[P2]` significa «carpeta del puesto 2».

```
chullasolution-space-apps-2026/
├── README.md             estás aquí
├── CONTRIBUTING.md       las reglas de trabajo, en una página
├── project.godot         [P1]  el proyecto de Godot: este es el archivo que se abre
│
├── core/                 [P1]  arranque del juego y unión de todo
├── scenes/               [P1]  escena principal (main.tscn)
├── export/               [P1]  exportar y publicar la versión web
│
├── simulation/           [P2]  energía, vida y escudo
├── data/
│   ├── nasa/             [P2]  datos de NASA ya reducidos
│   └── missions/         [P5]  datos de misiones y mejoras
│
├── world/                [P3]  la Luna, el domo, los módulos
├── camera/               [P4]  la cámara
├── interaction/          [P4]  clics y acciones
├── progression/          [P5]  misiones, reporte y árbol de mejoras
│
├── ui/                   [P6]  interfaz y tutorial
├── i18n/                 [P6]  textos en inglés y español
├── submission/           [P6]  póster y textos del envío
│
├── assets/
│   ├── 3d/               [P3]  modelos y texturas
│   ├── audio/            [P4]  sonidos y música
│   └── ui/               [P6]  iconos y tipografías
│
└── docs/                 [P1]  guías, mapa y contratos
    └── registro/                cada quien su archivo: puesto-N.md
```

### Los seis puestos

| Puesto | Rol | Carpetas |
|---|---|---|
| 1 | Integración y coordinación | `core/` · `scenes/` · `export/` · `docs/` · archivos de la raíz |
| 2 | Ciencia, simulación y datos | `simulation/` · `data/nasa/` |
| 3 | Mundo 3D y arte | `world/` · `assets/3d/` |
| 4 | Interacción y jugabilidad | `camera/` · `interaction/` · `assets/audio/` |
| 5 | Misiones, progresión y árbol | `progression/` · `data/missions/` |
| 6 | Interfaz, tutorial y textos | `ui/` · `i18n/` · `assets/ui/` · `submission/` |

Cada persona además lleva su propio registro en `docs/registro/puesto-N.md` (uso de IA, material de terceros, datos usados). Así nadie edita el mismo archivo a la vez.

### Integridad

- No usamos el logo de NASA ni decimos que NASA avale el proyecto.
- Los números del juego son **unidades de juego**, no datos de NASA, salvo los que figuren en `docs/DATA_PROVENANCE.md` con su fuente.
- Todo código, texto o imagen hecho con IA se anota en el registro de quien lo hizo.
