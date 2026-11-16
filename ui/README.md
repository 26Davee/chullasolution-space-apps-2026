# ui/

Interface, tutorial and in-game panels (Godot `Control` nodes built in code).

Main entry points:

| File | Purpose |
|---|---|
| `live_game.gd` | In-game controller: HUD, drawers, missions, rewards, saving. |
| `game_hud.gd`, `live_hud.gd` | Five resource bars, clock, storm banner, dock buttons. |
| `game_drawer.gd` | Side drawers: build, ice trip, repair, missions, upgrades, science, settings. |
| `intro.gd` | First-run tutorial with Timmy. |
| `ice_expedition.gd` | Ice trip state machine (three ice zones that refill every sunrise). |
| `save_slots_panel.gd`, `new_slot_setup.gd` | Three save slots and profile setup (age group, nickname). |
| `mission_clock.gd` | Readable clock: 4 min of sunlight + 4 min of night = one 29.53-Earth-day lunar cycle. |
| `timmy_voice.gd` | Reads guidance aloud with the operating system's text-to-speech. |

UI tests are in `ui/tests/`.
