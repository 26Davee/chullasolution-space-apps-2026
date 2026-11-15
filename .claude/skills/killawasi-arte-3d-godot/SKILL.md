---
name: "killawasi-arte-3d-godot"
description: "Modelar piezas 3D de Killawasi en Godot (módulos, astronauta, herramientas, cápsula) con aspecto redondeado low-poly estilo maqueta, no cuadrado ni antiguo."
---

# Killawasi · modelado 3D en Godot

Objetivo: que cada pieza se vea igual o mejor que las imágenes de la **Guía visual 3D** (KILLAWASI_Guia_Visual_3D_Carlos.html). Esas imágenes son la autoridad. Si lo que modelas no se parece a ellas al compararlo lado a lado, no está terminado.

## Por qué las IA lo hacen "antiguo" y "cuadrado"
Las IA arman todo con BoxMesh y CylinderMesh sin bisel, con proporciones realistas, materiales planos sin brillo y sin luz de acento. Eso da el aspecto de gráficos viejos. La referencia hace lo contrario:
- Formas **grandes, gordas y redondeadas**: bisel ancho en todas las aristas, nada de esquinas vivas.
- **Proporciones de juguete**: cabezas, tanques y patas más gruesos que en la vida real. Siluetas simples.
- **Pocos detalles pero grandes**: 2–3 tornillos gruesos, ventanas grandes, nada de textura fina.
- **Color con intención**: carcasa blanco hueso, acento turquesa, luces ámbar, vidrio cian. Nunca gris plano.
- **Luz**: sol cálido de lado, ambiente frío violeta, brillo (glow) en las partes emisivas.

## Regla de oro
Nunca uses `BoxMesh` ni `CylinderMesh` crudos para una pieza visible. Usa las funciones de `LowPoly` (abajo) o un modelo importado (.glb). Una caja sin bisel es un error.

## Paleta (usar estos colores, no inventar otros)
Espacio #04122E · Regolito #7C7890 (lila grisáceo) · Carcasas hueso #E9E2DA · Acento turquesa #2AA3B0 · Luz técnica cian #33C7D6 · Luz cálida ámbar #F2B544 · Visor #122B3D · Aviso coral #FF6F61 · Azul marino para botas, mangos y bandejas.
Materiales: `StandardMaterial3D`, roughness 0.55–0.8 (mate), metallic 0–0.1. Para luces y conectores: `emission_enabled = true`, color ámbar o cian, `emission_energy_multiplier` 1.5–3. El vidrio es cian semitransparente (`transparency = ALPHA`, alpha 0.55, roughness 0.15).

## Tres caminos para hacer una pieza (elige uno)
**A. Imagen a 3D (el más parecido a la referencia).** Subir las vistas aisladas de la guía (frente, perfil, espalda, tres cuartos) a un generador imagen→3D (Tripo, Meshy, Rodin o Hunyuan3D). Exportar .glb. Luego limpiar en Blender: Decimate hasta 1.500–6.000 triángulos por pieza, escala real, pivote en la base, separar en objetos las partes que se mueven (puerta, tolva, brazos), y revisar colores con la paleta. Guardar en `assets/3d/<pieza>.glb`. Anotar herramienta y licencia en `docs/DATA_PROVENANCE.md` y `docs/AI_USE.md`. Los resultados de estas herramientas varían: revisar siempre contra la guía.
**B. Blender con script.** Crear la malla con `bpy`: base simple + modificador **Bevel** (width 0.04–0.08, segments 2–3, Harden Normals activado) + `shade_smooth` en piezas de máquina o `shade_flat` en rocas. Exportar glTF 2.0 (.glb) con Y arriba. Aplicar escala y rotación antes de exportar.
**C. Solo Godot (para prototipos rápidos).** Usar el helper `LowPoly` de abajo. Sirve para domo, tanques, cajas y bases. Para astronauta y vicuña se ve mejor el camino A o B.

## Cómo se ve bien cada familia de formas
- **Cajas de máquina** (procesador, reciclador, batería): `caja_biselada` radio 0.06–0.12 y `seg` 2–3. Tolvas y ventanas como piezas separadas ligeramente metidas, nunca pegadas a ras.
- **Tanques y generadores**: `cilindro_biselado` con 8–12 lados y bisel 0.05–0.08. Hombros achaflanados, anillos turquesa, tres patas cortas y gruesas. Generador de oxígeno = dos columnas + puente de tubería; tanque de agua = una columna con ventana vertical.
- **Tuberías**: tubos gruesos (radio 0.06–0.09) con codos en curva y abrazaderas ámbar. Evitar tubos finos rectos.
- **Cápsula**: ovoide (esfera escalada 1 : 0.85 : 1 con 10–12 lados), base turquesa, cuatro patas finas con pies anchos, ventanas redondas ámbar, escalerilla aparte.
- **Domo**: `media_esfera` con material cian muy transparente y borde más claro. Separado, con su propio origen, para cambiar de aspecto según el escudo (100, 70, 30, 0).
- **Panel solar**: dos placas azul medianoche con 3×4 celdas grandes (líneas de 2 px), marco hueso, soporte con bisagra.
- **Astronauta y vicuña**: cabeza grande (1/3 de la altura), manos y botas grandes, visor oscuro sin rostro, mochila octogonal con dos tanques. Cada articulación es un nodo separado para animar.
- **Herramientas**: cabezas gruesas y compactas, color claro con borde cian; se deben reconocer a 6 % de la altura de pantalla.
- **Rocas y suelo**: caras planas facetadas (sin suavizar), color lila #7C7890 con variaciones de tono. Ver la skill `killawasi-escena-lunar-godot`.

## Helper `LowPoly` (probado en Godot 4.7.2)
Guardar en `assets/3d/herramientas/lowpoly.gd`. Cada función devuelve un `ArrayMesh`; asignarlo a un `MeshInstance3D.mesh`.

```gdscript
class_name LowPoly
extends RefCounted

static func caja_biselada(tam: Vector3, radio: float = 0.08, seg: int = 2) -> ArrayMesh:
	var h := tam * 0.5
	var r := minf(radio, minf(h.x, minf(h.y, h.z)) * 0.95)
	var inner := h - Vector3(r, r, r)
	var ejes: Array = []
	for k in 3:
		ejes.append(_valores(inner[k], r, seg))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 3:
		for signo in [1.0, -1.0]:
			var i1 := (k + 1) % 3
			var i2 := (k + 2) % 3
			var normal := Vector3.ZERO
			normal[k] = signo
			var l1: PackedFloat32Array = ejes[i1]
			var l2: PackedFloat32Array = ejes[i2]
			for i in range(l1.size() - 1):
				for j in range(l2.size() - 1):
					var q: Array = []
					for par in [[i, j], [i + 1, j], [i + 1, j + 1], [i, j + 1]]:
						var p := Vector3.ZERO
						p[k] = signo * h[k]
						p[i1] = l1[par[0]]
						p[i2] = l2[par[1]]
						q.append(_redondear(p, inner, r))
					_tri(st, q[0], q[1], q[2], normal)
					_tri(st, q[0], q[2], q[3], normal)
	st.generate_normals()  # sin smooth groups: caras planas
	return st.commit()

static func cilindro_biselado(radio: float, alto: float, lados: int = 10, bisel: float = 0.06) -> ArrayMesh:
	var b := minf(bisel, minf(radio, alto * 0.5) * 0.9)
	var perfil := [Vector2(0, -alto * 0.5), Vector2(radio - b, -alto * 0.5), Vector2(radio, -alto * 0.5 + b),
		Vector2(radio, alto * 0.5 - b), Vector2(radio - b, alto * 0.5), Vector2(0, alto * 0.5)]
	return _revolucion(perfil, lados)

static func media_esfera(radio: float, anillos: int = 5, lados: int = 12) -> ArrayMesh:
	var perfil: Array = []
	for i in range(anillos + 1):
		var a := (PI * 0.5) * float(i) / anillos
		perfil.append(Vector2(radio * cos(a), radio * sin(a)))
	return _revolucion(perfil, lados)

static func _revolucion(perfil: Array, lados: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for s in lados:
		var a0 := TAU * s / lados
		var a1 := TAU * (s + 1) / lados
		for k in range(perfil.size() - 1):
			var p0: Vector2 = perfil[k]
			var p1: Vector2 = perfil[k + 1]
			var v00 := Vector3(p0.x * cos(a0), p0.y, p0.x * sin(a0))
			var v01 := Vector3(p0.x * cos(a1), p0.y, p0.x * sin(a1))
			var v10 := Vector3(p1.x * cos(a0), p1.y, p1.x * sin(a0))
			var v11 := Vector3(p1.x * cos(a1), p1.y, p1.x * sin(a1))
			var centro := (v00 + v01 + v10 + v11) * 0.25
			var hacia_fuera := Vector3(centro.x, 0.0, centro.z)
			if absf(p0.x - p1.x) > 0.0001 and absf(p0.y - p1.y) < 0.0001:
				hacia_fuera = Vector3(0, 1 if p0.y > 0 else -1, 0)
			elif p0.x < 0.0001 or p1.x < 0.0001:
				hacia_fuera = centro
			_tri(st, v00, v10, v11, hacia_fuera)
			_tri(st, v00, v11, v01, hacia_fuera)
	st.generate_normals()
	return st.commit()

static func _valores(inner: float, r: float, seg: int) -> PackedFloat32Array:
	var neg: Array = []
	for k in range(seg + 1):
		var th := (PI * 0.5) * (1.0 - float(k) / seg)
		neg.append(-inner - r * sin(th))
	var out := PackedFloat32Array()
	for v in neg:
		out.append(v)
	for k in range(neg.size() - 1, -1, -1):
		out.append(-neg[k])
	return out

static func _redondear(p: Vector3, inner: Vector3, r: float) -> Vector3:
	var c := Vector3(clampf(p.x, -inner.x, inner.x), clampf(p.y, -inner.y, inner.y), clampf(p.z, -inner.z, inner.z))
	var off := p - c
	if off.length() < 0.00001:
		return p
	return c + off.normalized() * r

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, hacia_fuera: Vector3) -> void:
	# Godot usa el sentido de las agujas del reloj como cara frontal
	var nrm := (b - a).cross(c - a)
	if nrm.dot(hacia_fuera) > 0.0:
		var t := b
		b = c
		c = t
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
```

Ejemplo: `$Cuerpo.mesh = LowPoly.caja_biselada(Vector3(1.2, 0.8, 0.9), 0.1, 3)`.

## Estructura de cada escena de pieza
- Archivo `assets/3d/<pieza>.tscn` autocontenida (nada de dependencias a otras escenas del juego).
- Pivote en la base, en el suelo, centrado. Frente hacia −Z (convención de Godot).
- Partes móviles como nodos hijos con nombre claro (`Tolva`, `Puerta`, `Bisagra`).
- Marcadores como `Marker3D` donde la guía los pide (`MarcadorEntrada`, `MarcadorSalida`, `MarcadorAcople`).
- Escala: astronauta ≈ 1,95 u de alto; casilla del mapa ≈ 2 u.

## Revisión obligatoria antes de dar la pieza por terminada
1. Colocarla en la escena de juego con la cámara a 45° y compararla con la imagen "Instalado · cámara 45°" de la guía.
2. Prueba del 6 %: reducir hasta que la pieza mida el 6 % del alto de pantalla. Debe reconocerse la silueta.
3. Lista de errores a descartar: esquinas vivas, tubos finos, gris plano sin acento, partes pegadas a ras (z-fighting), pivote fuera de la base, piezas que atraviesan el cuerpo, más de 6.000 triángulos, texto o logos NASA.
4. Si el resultado no se parece a la referencia, **repetir**; no entregarlo con la excusa de que es low-poly.