# Pruebas

Prueba sin abrir la ventana del juego (necesita Godot 4.7 en el PATH o la ruta completa):

```
godot --headless --path . --script tests/test_flujo.gd
```

Imprime `OK` o `FALLA` por cada comprobación y termina con `FALLOS: 0` si todo va bien.
Cubre `GameState` (límites, cobro, señales) y el recorrido título → modo → juego.
Si existe `simulation/simulacion.gd`, también prueba que quede enchufada.
