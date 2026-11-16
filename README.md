# KILLAWASI · Junior Astronaut Mission Trainer

**Build a Moon base, keep your crew alive, and learn how real astronauts survive.**

*Killawasi* means "Moon House" in Kichwa. It is a 3D educational game for children aged 7 to 12, made by team **ChullaSolution** (ESPOCH, Riobamba, Ecuador) for the **NASA Space Apps Challenge 2026**, challenge *Build a Junior Astronaut Mission Trainer*.

[![Watch the 30-second trailer](https://img.youtube.com/vi/QMfOx2_RUuQ/hqdefault.jpg)](https://youtu.be/QMfOx2_RUuQ)

▶ **Trailer:** [English](https://youtu.be/QMfOx2_RUuQ) · [Español](https://youtu.be/mKBG4V6mWq4)

> Student project. It is not endorsed by NASA and uses no NASA logos or insignia.

---

## Play

| Version | How |
|---|---|
| **Browser** | [Play Killawasi now](https://26davee.itch.io/killawasi), or download `Killawasi_web.zip` from [Releases](../../releases/latest). Works in Chrome, Edge and Firefox. |
| **Windows (offline)** | Download `Killawasi_windows.zip` from [Releases](../../releases/latest), unzip and run `Killawasi.exe`. No internet needed. |
| **From source** | Install [Godot 4.7.2](https://godotengine.org/download), open `project.godot` and press F5. |

The game is in **English and Spanish** (EN/ES button on the main menu).

## What the player does

You land on the Moon with **Timmy**, an astronaut vicuña inspired by the Andean vicuña, and build a small outpost that must keep its crew alive.

- **Choose a mode.** *Cadet* (ages 7–9) has guided missions and checkpoints. *Engineer* (ages 10–12) has higher costs and restarts the whole expedition if the base fails.
- **Watch five bars:** base energy, water, oxygen, dome shield and robot battery.
- **Use sunlight.** Solar panels only work in daylight. One lunar day lasts about 29.5 Earth days, compressed in the game to 4 minutes of sunlight and 4 minutes of night.
- **Collect ice.** Ice is the only resource you gather. Send the robot to a crater, bring ice back, turn it into water, then use water and energy to make oxygen.
- **Survive solar storms.** A countdown warns you before radiation arrives; repair the dome shield in time. The storm cloud is a symbol: real solar particle events are invisible.
- **Complete 16 missions.** Each one ends with a science card that explains the real fact behind it, with its NASA source. Stars unlock upgrades.

There is no game-over screen for young players: if something goes wrong, the mission report explains what happened and how to do better.

## Real science inside

| In the game | Real basis |
|---|---|
| Day/night cycle | Lunar synodic day of 29.53 Earth days |
| Solar panel output | Solar irradiance of ~1,361 W/m² (NASA TSIS-1) |
| Ice in shadowed craters | LCROSS (2009): water ice mixed into the soil of permanently shadowed craters |
| Coldest places | LRO Diviner: about −247 °C inside polar craters that never see sunlight |
| Solar storms | Solar particle events measured by LRO CRaTER; alerts from NASA's DONKI space-weather database |
| Water and oxygen recycling | ISS Environmental Control and Life Support System (ECLSS) |
| Shielding with lunar soil | NASA studies of regolith radiation shielding |

All sources, units and transformations are in [`docs/DATA_PROVENANCE.md`](docs/DATA_PROVENANCE.md) and [`docs/DATOS_NASA.md`](docs/DATOS_NASA.md). Simulation rates that are not NASA data are labelled as game units.

## Project structure

```
core/          game bootstrap, shared state (GameState), simulation
scenes/        main.tscn and the playable base
ui/            interface, tutorial, HUD, drawers, save slots (+ ui/tests)
progression/   16 missions, upgrades, saving
data/missions/ mission, upgrade and supply data (EN + ES)
interaction/   moving the robot, placing modules, routes
world/         lunar terrain, sky, landing cinematic
camera/        fixed-angle camera
assets/        3D models, shaders, AI-marked images, fonts
i18n/          English and Spanish text
docs/          science data, target audience, AI use, licenses
docs/team/     hackathon working documents and per-person logs
```

## Tests

```
godot --headless --path . --script tests/test_flujo.gd
godot --headless --path . --script ui/tests/test_live_game.gd
```

There are 8 automated test scripts (`tests/` and `ui/tests/`). Before submitting, we also ran automated playthroughs of the full 16-mission campaign in both modes and both languages.

## Team ChullaSolution

| Member | Role |
|---|---|
| Angel David Espinoza Ureta | Integration and coordination |
| Anahi Elizabeth Tixe Buñay | Science, simulation and NASA data |
| Carlos Andres Valladares Rivas | 3D world and art |
| Nicolás Ladino | Interaction and gameplay |
| Gael Jair Rivera Aguilar | Missions, progression and upgrade tree |
| Andrea Gabriela Astudillo Dávalos | Interface, tutorial and text |

## Use of AI

ChullaSolution created and built Killawasi. AI tools assisted with selected code and integration tasks, debugging and review, some text work, and a limited set of marked illustrations and trailer narration; they did not create the game as a whole. Team members directed, reviewed and tested the published work. AI tools are disclosed separately from the human team. Full details: [`docs/AI_USE.md`](docs/AI_USE.md).

## Licenses

Game code and original content: [MIT License](LICENSE). Third-party fonts and other material: [`docs/ASSETS_LICENSES.md`](docs/ASSETS_LICENSES.md).

---

## En español

**Killawasi** («Casa de la Luna» en kichwa) es un juego educativo en 3D para niñas y niños de 7 a 12 años. Construyes una base lunar con Timmy, una vicuña astronauta, administras energía, agua, oxígeno y escudo, recoges hielo, sobrevives a tormentas solares y completas 16 misiones con cartas científicas basadas en datos de NASA. Tiene dos modos: **Cadete** (7–9 años) e **Ingeniero** (10–12 años), y se juega en español o inglés.

**Jugar en el navegador:** [Abrir Killawasi en itch.io](https://26davee.itch.io/killawasi).

Proyecto estudiantil del equipo ChullaSolution (ESPOCH, Riobamba) para el NASA Space Apps Challenge 2026. No está avalado por NASA.
