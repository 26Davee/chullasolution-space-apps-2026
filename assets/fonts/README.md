# Fuentes de respaldo

Godot usa por defecto Open Sans, que no trae símbolos como ★ ✓ ⚠ ⚡ → ni emojis.
En la versión web no hay fuentes del sistema, así que esos símbolos salían como cuadritos.
`core/game_state.gd` agrega estas dos fuentes libres como respaldo:

| Archivo | Fuente | Licencia |
|---|---|---|
| `DejaVuSans.ttf` | DejaVu Sans | Bitstream Vera License + dominio público (`LICENSE-DejaVu.txt`) |
| `NotoEmoji-Regular.ttf` | Noto Emoji 2.001 (Google) | SIL Open Font License 1.1 (`LICENSE-NotoEmoji.txt`) |
