# Pruebas

**Lógica, sin ventana** (necesita Godot 4.7 en el PATH o la ruta completa):

```
godot --headless --path . --script tests/test_flujo.gd
```

Imprime `OK` o `FALLA` por cada comprobación y termina con `FALLOS: 0` si todo va bien. Recorre intro → aterrizaje → juego, construye el primer panel, completa la misión 1 y prueba los límites de `GameState`.

**Capturas del juego** (solo Linux con `xvfb`, sirve para que una IA vea la escena):

```
xvfb-run -a godot --path . --rendering-driver opengl3 --script tests/captura_juego.gd
```

Guarda `captura_intro.png` y `captura_juego.png` en `/tmp`.
