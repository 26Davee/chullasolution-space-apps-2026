# core/

Game bootstrap and shared state.

| File | Purpose |
|---|---|
| `main.gd` | Entry point: save slots, profile setup, intro, and switching between menu and game. |
| `game_state.gd` | Autoload `GameState`: resources (energy, water, oxygen, shield, robot battery), day/night clock based on the 29.53-day lunar cycle, language, fallback fonts. |
| `juego.gd` | Base game scene logic: simulation tick, storms, building, ice processing, robot charging. |
