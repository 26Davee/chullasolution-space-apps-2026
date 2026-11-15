extends RefCounted
## Kit de arte de Killawasi: paleta, materiales compartidos y mallas redondeadas.
## Todo es geometría procedural propia. No usa texturas ni modelos de terceros.
## Lo usa `generar_killawasi_v2.gd` para escribir las escenas de `assets/3d/`.

const MAT_DIR := "res://assets/3d/materiales/"

## c = color · r = rugosidad · m = metal · e = energía de emisión · ec = color de emisión
## a = alfa · rim = brillo de contorno · v = usa color de vértice · u = sin sombreado
const PALETA := {
	"hueso": {"c": "#EEE7E0", "r": 0.58, "rim": 0.45},
	"hueso_sombra": {"c": "#CBC4D2", "r": 0.7, "rim": 0.2},
	"turquesa": {"c": "#1F9DA6", "r": 0.48, "rim": 0.45},
	"turquesa_osc": {"c": "#1C7C8B", "r": 0.55, "rim": 0.25},
	"marino": {"c": "#1D3557", "r": 0.55, "rim": 0.3},
	"marino_osc": {"c": "#14233D", "r": 0.6, "rim": 0.2},
	"visor": {"c": "#0E2238", "r": 0.12, "m": 0.35, "rim": 0.9},
	"ambar": {"c": "#FFB93A", "r": 0.4, "e": 1.7, "ec": "#FFA21F"},
	"ambar_suave": {"c": "#FFC55A", "r": 0.4, "e": 1.0, "ec": "#FFA92E"},
	"ambar_mate": {"c": "#F0A52B", "r": 0.42, "m": 0.15, "rim": 0.35},
	"naranja_marco": {"c": "#D9801A", "r": 0.5, "rim": 0.2},
	"cian_luz": {"c": "#5BE6F2", "r": 0.35, "e": 2.0, "ec": "#33C7D6"},
	"cian_fondo": {"c": "#0F6E86", "r": 0.4, "e": 0.55, "ec": "#1FB6D1"},
	"hielo": {"c": "#BDEBFF", "r": 0.16, "e": 0.55, "ec": "#49C9F0", "rim": 0.8},
	"hielo_osc": {"c": "#7FD3F2", "r": 0.2, "e": 0.45, "ec": "#2FB4E3", "rim": 0.6},
	"vidrio": {"c": "#8FE7F5", "r": 0.08, "a": 0.3, "rim": 0.9},
	"agua": {"c": "#3CC6EE", "r": 0.12, "e": 0.75, "ec": "#22B5E6", "a": 0.86},
	"acero": {"c": "#A9B4C4", "r": 0.42, "m": 0.45, "rim": 0.3},
	"acero_osc": {"c": "#5D6A80", "r": 0.5, "m": 0.35, "rim": 0.2},
	"goma": {"c": "#262A38", "r": 0.85, "rim": 0.25},
	"panel_azul": {"c": "#1C49B3", "r": 0.55, "m": 0.05, "rim": 0.4, "e": 0.2, "ec": "#2C62E0"},
	"panel_linea": {"c": "#BFD6FF", "r": 0.4, "e": 0.35, "ec": "#9EC0FF"},
	"canela": {"c": "#E0914B", "r": 0.72, "rim": 0.45},
	"canela_osc": {"c": "#B96A30", "r": 0.75, "rim": 0.3},
	"crema": {"c": "#F8E7CC", "r": 0.75, "rim": 0.4},
	"rosa": {"c": "#F4A6A0", "r": 0.7},
	"negro": {"c": "#1B1A22", "r": 0.3, "rim": 0.5},
	"blanco": {"c": "#FFFFFF", "r": 0.3, "e": 0.6, "ec": "#FFFFFF"},
	"hoja": {"c": "#63C83F", "r": 0.6, "rim": 0.4},
	"hoja_osc": {"c": "#3C9A2E", "r": 0.65, "rim": 0.3},
	"tierra": {"c": "#5B3A2B", "r": 0.9},
	"coral": {"c": "#FF7B6E", "r": 0.55, "e": 0.75, "ec": "#FF6F61", "rim": 0.5},
	"cian": {"c": "#27C4D8", "r": 0.45, "rim": 0.5},
	"llama": {"c": "#FFE3A0", "r": 0.5, "e": 3.0, "ec": "#FFB347", "a": 0.75},
	"burbuja": {"c": "#D6F7FF", "r": 0.05, "a": 0.16, "rim": 1.0},
	"estrella": {"c": "#FFFFFF", "r": 1.0, "u": true, "v": true},
	"regolito": {"c": "#FFFFFF", "r": 0.92, "v": true},
	"roca": {"c": "#FFFFFF", "r": 0.9, "v": true},
	"camino": {"c": "#A29CB8", "r": 0.8},
	"camino_borde": {"c": "#CFCADB", "r": 0.8},
	"crater_fondo": {"c": "#555070", "r": 0.95},
	"crater_borde": {"c": "#8C87A6", "r": 0.9},
}

static var _mats := {}
static var _meshes := {}
static var guardar_materiales := true


## Material compartido de la paleta. Se guarda como `.tres` para que todas las escenas usen el mismo.
static func mat(id: String) -> StandardMaterial3D:
	if _mats.has(id):
		return _mats[id]
	assert(PALETA.has(id), "Material fuera de la paleta: " + id)
	var d: Dictionary = PALETA[id]
	var m := StandardMaterial3D.new()
	var color := Color(String(d["c"]))
	color.a = float(d.get("a", 1.0))
	m.albedo_color = color
	m.roughness = float(d.get("r", 0.6))
	m.metallic = float(d.get("m", 0.0))
	m.metallic_specular = 0.5
	if d.has("e"):
		m.emission_enabled = true
		m.emission = Color(String(d.get("ec", d["c"])))
		m.emission_energy_multiplier = float(d["e"])
	if d.has("rim"):
		m.rim_enabled = true
		m.rim = float(d["rim"]) * 0.4
		m.rim_tint = 0.6
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if d.get("v", false):
		m.vertex_color_use_as_albedo = true
	if d.get("u", false):
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.resource_name = id
	if guardar_materiales:
		DirAccess.make_dir_recursive_absolute(MAT_DIR)
		var path := MAT_DIR + id + ".tres"
		ResourceSaver.save(m, path)
		m.take_over_path(path)
	_mats[id] = m
	return m


# ---------------------------------------------------------------- mallas

## Caja con todas las aristas redondeadas y normales suaves. `estrechar` reduce el techo (x, z).
static func rbox(tam: Vector3, radio: float, seg: int = 3, estrechar := Vector2.ONE) -> ArrayMesh:
	var key := "rbox|%s|%.4f|%d|%s" % [tam, radio, seg, estrechar]
	if _meshes.has(key):
		return _meshes[key]
	var h := tam * 0.5
	var r := minf(radio, minf(h.x, minf(h.y, h.z)) * 0.98)
	var inner := h - Vector3(r, r, r)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 3:
		var i1 := (k + 1) % 3
		var i2 := (k + 2) % 3
		var l1 := _pasos(inner[i1], r, seg)
		var l2 := _pasos(inner[i2], r, seg)
		for signo in [1.0, -1.0]:
			for i in l1.size() - 1:
				for j in l2.size() - 1:
					var ps: Array[Vector3] = []
					var ns: Array[Vector3] = []
					for par in [[i, j], [i + 1, j], [i + 1, j + 1], [i, j + 1]]:
						var p := Vector3.ZERO
						p[k] = signo * h[k]
						p[i1] = l1[par[0]]
						p[i2] = l2[par[1]]
						var c := Vector3(clampf(p.x, -inner.x, inner.x), clampf(p.y, -inner.y, inner.y), clampf(p.z, -inner.z, inner.z))
						var off := p - c
						var n := Vector3.ZERO
						n[k] = signo
						if off.length() > 0.00001:
							n = off.normalized()
						var q := c + n * r
						var t := (q.y + h.y) / (2.0 * h.y)
						q.x *= lerpf(1.0, estrechar.x, t)
						q.z *= lerpf(1.0, estrechar.y, t)
						ps.append(q)
						ns.append(n)
					_quad(st, ps, ns)
	st.index()
	var mesh := st.commit()
	_meshes[key] = mesh
	return mesh


## Sólido de revolución. `perfil` es una lista de Vector2(radio, altura) recorrida de abajo arriba
## por la cara exterior. `pliegue` es el ángulo a partir del cual una arista queda marcada.
static func lathe(perfil: Array, lados: int = 20, pliegue: float = 40.0, faceta: float = 0.0) -> ArrayMesh:
	var key := "lathe|%s|%d|%.1f|%.2f" % [perfil, lados, pliegue, faceta]
	if _meshes.has(key):
		return _meshes[key]
	var seg_n: Array[Vector2] = []
	for k in perfil.size() - 1:
		var d: Vector2 = perfil[k + 1] - perfil[k]
		seg_n.append(Vector2(d.y, -d.x).normalized())
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cos_pliegue := cos(deg_to_rad(pliegue))
	for k in perfil.size() - 1:
		var p0: Vector2 = perfil[k]
		var p1: Vector2 = perfil[k + 1]
		var n0 := seg_n[k]
		var n1 := seg_n[k]
		if k > 0 and seg_n[k - 1].dot(seg_n[k]) > cos_pliegue:
			n0 = (seg_n[k - 1] + seg_n[k]).normalized()
		if k < seg_n.size() - 1 and seg_n[k + 1].dot(seg_n[k]) > cos_pliegue:
			n1 = (seg_n[k + 1] + seg_n[k]).normalized()
		for s in lados:
			var a0 := TAU * s / lados
			var a1 := TAU * (s + 1) / lados
			var am := (a0 + a1) * 0.5
			var ps: Array[Vector3] = [_rev(p0, a0), _rev(p1, a0), _rev(p1, a1), _rev(p0, a1)]
			var fn := _rev_n(seg_n[k], am)
			var ns: Array[Vector3] = [_rev_n(n0, a0), _rev_n(n1, a0), _rev_n(n1, a1), _rev_n(n0, a1)]
			for q in 4:
				ns[q] = ns[q].lerp(fn, faceta).normalized()
			_quad(st, ps, ns)
	st.index()
	var mesh := st.commit()
	_meshes[key] = mesh
	return mesh


## Tubo a lo largo de una ruta, con codos curvos (`curva` = radio del codo).
static func tube(ruta: Array, radio: float, lados: int = 10, curva: float = 0.0, tapas := true) -> ArrayMesh:
	var key := "tube|%s|%.4f|%d|%.3f|%s" % [ruta, radio, lados, curva, tapas]
	if _meshes.has(key):
		return _meshes[key]
	var pts: Array[Vector3] = []
	if curva > 0.0 and ruta.size() > 2:
		pts.append(ruta[0])
		for i in range(1, ruta.size() - 1):
			var a: Vector3 = ruta[i - 1]
			var b: Vector3 = ruta[i]
			var c: Vector3 = ruta[i + 1]
			var ra := minf(curva, a.distance_to(b) * 0.5)
			var rc := minf(curva, c.distance_to(b) * 0.5)
			var pa := b + (a - b).normalized() * ra
			var pc := b + (c - b).normalized() * rc
			for t in 7:
				var u := float(t) / 6.0
				pts.append(pa.lerp(b, u).lerp(b.lerp(pc, u), u))
		pts.append(ruta[ruta.size() - 1])
	else:
		for p in ruta:
			pts.append(p)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var first_t := (pts[1] - pts[0]).normalized()
	var up := Vector3.UP if absf(first_t.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
	var prev_p: Array[Vector3] = []
	var prev_n: Array[Vector3] = []
	for i in pts.size():
		var t: Vector3
		if i == 0:
			t = first_t
		elif i == pts.size() - 1:
			t = (pts[i] - pts[i - 1]).normalized()
		else:
			t = ((pts[i] - pts[i - 1]).normalized() + (pts[i + 1] - pts[i]).normalized()).normalized()
		up = (up - t * up.dot(t)).normalized()
		var side := t.cross(up).normalized()
		var ring_p: Array[Vector3] = []
		var ring_n: Array[Vector3] = []
		for j in lados + 1:
			var ang := TAU * j / lados
			var dir := up * cos(ang) + side * sin(ang)
			ring_p.append(pts[i] + dir * radio)
			ring_n.append(dir)
		if i > 0:
			for j in lados:
				_quad(st, [prev_p[j], ring_p[j], ring_p[j + 1], prev_p[j + 1]], [prev_n[j], ring_n[j], ring_n[j + 1], prev_n[j + 1]])
		if tapas and (i == 0 or i == pts.size() - 1):
			var cap_n := -t if i == 0 else t
			for j in lados:
				_tri(st, [pts[i], ring_p[j], ring_p[j + 1]], [cap_n, cap_n, cap_n])
		prev_p = ring_p
		prev_n = ring_n
	st.index()
	var mesh := st.commit()
	_meshes[key] = mesh
	return mesh


## Placa: contorno 2D (XY) extruido en Z con bisel. `contorno` y `tapa` tienen el mismo número de puntos.
static func extrude(contorno: PackedVector2Array, tapa: PackedVector2Array, fondo: float, bisel: float) -> ArrayMesh:
	var key := "ext|%s|%s|%.4f|%.4f" % [contorno, tapa, fondo, bisel]
	if _meshes.has(key):
		return _meshes[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := contorno.size()
	var hz := fondo * 0.5
	var b := minf(bisel, hz * 0.95)
	var centro := Vector2.ZERO
	for p in contorno:
		centro += p
	centro /= n
	var out_n: Array[Vector3] = []
	for i in n:
		var prev := contorno[(i - 1 + n) % n]
		var next := contorno[(i + 1) % n]
		var tang := (next - prev).normalized()
		var nn := Vector2(tang.y, -tang.x)
		if nn.dot(contorno[i] - centro) < 0.0:
			nn = -nn
		out_n.append(Vector3(nn.x, nn.y, 0.0))
	for i in n:
		var j := (i + 1) % n
		# costado
		_quad(st, [_v3(contorno[i], -hz + b), _v3(contorno[i], hz - b), _v3(contorno[j], hz - b), _v3(contorno[j], -hz + b)], [out_n[i], out_n[i], out_n[j], out_n[j]])
		# biseles
		for signo in [1.0, -1.0]:
			var ni := (out_n[i] + Vector3(0, 0, signo)).normalized()
			var nj := (out_n[j] + Vector3(0, 0, signo)).normalized()
			_quad(st, [_v3(contorno[i], signo * (hz - b)), _v3(tapa[i], signo * hz), _v3(tapa[j], signo * hz), _v3(contorno[j], signo * (hz - b))], [ni, ni, nj, nj])
			var cn := Vector3(0, 0, signo)
			_tri(st, [_v3(centro, signo * hz), _v3(tapa[i], signo * hz), _v3(tapa[j], signo * hz)], [cn, cn, cn])
	st.index()
	var mesh := st.commit()
	_meshes[key] = mesh
	return mesh


## Placa rectangular de esquinas redondeadas (plano XY, grosor en Z).
static func plate(ancho: float, alto: float, fondo: float, radio: float, bisel: float = 0.02) -> ArrayMesh:
	return extrude(rrect(ancho, alto, radio), rrect(ancho - bisel * 2.0, alto - bisel * 2.0, maxf(radio - bisel, 0.005)), fondo, bisel)


## Placa con contorno libre; la tapa se obtiene encogiendo hacia el centro.
static func plate_shape(contorno: PackedVector2Array, fondo: float, bisel: float = 0.02) -> ArrayMesh:
	var centro := Vector2.ZERO
	var radio := 0.0
	for p in contorno:
		centro += p
	centro /= contorno.size()
	for p in contorno:
		radio += p.distance_to(centro)
	radio /= contorno.size()
	var tapa := PackedVector2Array()
	for p in contorno:
		tapa.append(centro + (p - centro) * (1.0 - bisel / maxf(radio, 0.001)))
	return extrude(contorno, tapa, fondo, bisel)


static func rrect(ancho: float, alto: float, radio: float, seg: int = 5) -> PackedVector2Array:
	var r := minf(radio, minf(ancho, alto) * 0.5)
	var pts := PackedVector2Array()
	var cx := ancho * 0.5 - r
	var cy := alto * 0.5 - r
	var centros := [Vector2(cx, cy), Vector2(-cx, cy), Vector2(-cx, -cy), Vector2(cx, -cy)]
	for q in 4:
		for s in seg + 1:
			var a := PI * 0.5 * (q + float(s) / seg)
			pts.append(centros[q] + Vector2(cos(a), sin(a)) * r)
	return pts


## Octógono (rectángulo con las esquinas cortadas).
static func octagon(ancho: float, alto: float, corte: float) -> PackedVector2Array:
	var x := ancho * 0.5
	var y := alto * 0.5
	return PackedVector2Array([Vector2(x, y - corte), Vector2(x - corte, y), Vector2(-x + corte, y), Vector2(-x, y - corte),
		Vector2(-x, -y + corte), Vector2(-x + corte, -y), Vector2(x - corte, -y), Vector2(x, -y + corte)])


## Arco de puerta: base recta y parte superior redonda.
static func arch(ancho: float, alto: float, seg: int = 10) -> PackedVector2Array:
	var r := ancho * 0.5
	var pts := PackedVector2Array()
	pts.append(Vector2(r, -alto * 0.5))
	for s in seg + 1:
		var a := PI * float(s) / seg
		pts.append(Vector2(cos(a) * r, alto * 0.5 - r + sin(a) * r))
	pts.append(Vector2(-r, -alto * 0.5))
	return pts


## Gota de agua plana (para iconos).
static func drop_shape(ancho: float, alto: float, seg: int = 14) -> PackedVector2Array:
	var r := ancho * 0.5
	var pts := PackedVector2Array()
	var cy := -alto * 0.5 + r
	for s in seg + 1:
		var a := lerpf(deg_to_rad(-215.0), deg_to_rad(35.0), float(s) / seg)
		pts.append(Vector2(cos(a) * r, cy + sin(a) * r))
	pts.append(Vector2(0.0, alto * 0.5))
	return pts


static func sphere(radio: float, lados: int = 24, anillos: int = 12, alto: float = -1.0) -> SphereMesh:
	var key := "sph|%.4f|%d|%d|%.4f" % [radio, lados, anillos, alto]
	if _meshes.has(key):
		return _meshes[key]
	var m := SphereMesh.new()
	m.radius = radio
	m.height = radio * 2.0 if alto < 0.0 else alto
	m.radial_segments = lados
	m.rings = anillos
	_meshes[key] = m
	return m


static func capsule(radio: float, alto: float, lados: int = 18) -> CapsuleMesh:
	var key := "cap|%.4f|%.4f|%d" % [radio, alto, lados]
	if _meshes.has(key):
		return _meshes[key]
	var m := CapsuleMesh.new()
	m.radius = radio
	m.height = maxf(alto, radio * 2.0)
	m.radial_segments = lados
	m.rings = 6
	_meshes[key] = m
	return m


static func torus(radio: float, grosor: float, lados: int = 24, seccion: int = 10) -> TorusMesh:
	var key := "tor|%.4f|%.4f|%d|%d" % [radio, grosor, lados, seccion]
	if _meshes.has(key):
		return _meshes[key]
	var m := TorusMesh.new()
	m.inner_radius = radio - grosor
	m.outer_radius = radio + grosor
	m.rings = lados
	m.ring_segments = seccion
	_meshes[key] = m
	return m


## Cilindro de cantos redondeados (eje Y), centrado en el origen.
static func drum(radio: float, alto: float, lados: int = 20, bisel: float = 0.05, radio_sup: float = -1.0) -> ArrayMesh:
	var rs := radio if radio_sup < 0.0 else radio_sup
	var b := minf(bisel, minf(minf(radio, rs), alto * 0.5) * 0.9)
	var h := alto * 0.5
	var perfil: Array = [Vector2(0, -h), Vector2(radio - b, -h)]
	for s in range(1, 4):
		var a := PI * 0.5 * s / 3.0
		perfil.append(Vector2(radio - b + sin(a) * b, -h + b - cos(a) * b))
	for s in range(0, 3):
		var a := PI * 0.5 * s / 3.0
		perfil.append(Vector2(rs - b + cos(a) * b, h - b + sin(a) * b))
	perfil.append(Vector2(rs - b, h))
	perfil.append(Vector2(0, h))
	return lathe(perfil, lados, 50.0)


## Cristal de hielo facetado (prisma hexagonal con punta).
static func crystal(alto: float, radio: float, lados: int = 6) -> ArrayMesh:
	return lathe([Vector2(0, 0), Vector2(radio * 0.85, alto * 0.08), Vector2(radio, alto * 0.62), Vector2(0, alto)], lados, 0.0, 1.0)


## Roca facetada: icosaedro deformado, con color de vértice por cara.
static func rock(radio: float, semilla: int, aplastar := Vector3(1.0, 0.62, 0.9), ruido := 0.24, base := Color("#8580A0")) -> ArrayMesh:
	var key := "rock|%.3f|%d|%s|%.3f|%s" % [radio, semilla, aplastar, ruido, base]
	if _meshes.has(key):
		return _meshes[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var t := (1.0 + sqrt(5.0)) / 2.0
	var verts: Array[Vector3] = [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]
	var caras := [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
		[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]]
	for i in verts.size():
		var v := verts[i].normalized() * (1.0 + rng.randf_range(-ruido, ruido))
		verts[i] = v * aplastar * radio
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for cara in caras:
		var a := verts[cara[0]]
		var b := verts[cara[1]]
		var c := verts[cara[2]]
		var n := ((a + b + c) / 3.0).normalized()
		var fn := (b - a).cross(c - a).normalized()
		if fn.dot(n) < 0.0:
			fn = -fn
		st.set_color(base.lightened(rng.randf_range(0.0, 0.12)) if fn.y > 0.2 else base.darkened(rng.randf_range(0.02, 0.14)))
		_tri(st, [a, b, c], [fn, fn, fn])
	st.index()
	var mesh := st.commit()
	_meshes[key] = mesh
	return mesh


# ---------------------------------------------------------------- internos

static func _pasos(inner: float, r: float, seg: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for k in seg + 1:
		out.append(-inner - r * cos(PI * 0.5 * k / seg))
	for k in range(seg, -1, -1):
		out.append(inner + r * cos(PI * 0.5 * k / seg))
	return out


static func _rev(p: Vector2, a: float) -> Vector3:
	return Vector3(p.x * cos(a), p.y, p.x * sin(a))


static func _rev_n(n: Vector2, a: float) -> Vector3:
	return Vector3(n.x * cos(a), n.y, n.x * sin(a)).normalized()


static func _v3(p: Vector2, z: float) -> Vector3:
	return Vector3(p.x, p.y, z)


static func _quad(st: SurfaceTool, ps: Array, ns: Array) -> void:
	_tri(st, [ps[0], ps[1], ps[2]], [ns[0], ns[1], ns[2]])
	_tri(st, [ps[0], ps[2], ps[3]], [ns[0], ns[2], ns[3]])


## Añade un triángulo orientado hacia fuera según sus normales (Godot: cara frontal horaria).
static func _tri(st: SurfaceTool, ps: Array, ns: Array) -> void:
	var a: Vector3 = ps[0]
	var b: Vector3 = ps[1]
	var c: Vector3 = ps[2]
	var geo := (b - a).cross(c - a)
	if geo.length_squared() < 1e-12:
		return
	var fuera: Vector3 = ns[0] + ns[1] + ns[2]
	var orden := [0, 1, 2]
	if geo.dot(fuera) > 0.0:
		orden = [0, 2, 1]
	for i in orden:
		st.set_normal(ns[i])
		st.add_vertex(ps[i])


# ---------------------------------------------------------------- montaje

## Añade una malla como hijo. `rot` va en grados.
static func part(padre: Node, nombre: String, malla: Mesh, material: String, pos := Vector3.ZERO, rot := Vector3.ZERO, escala := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nombre
	mi.mesh = malla
	mi.material_override = mat(material)
	mi.position = pos
	mi.rotation_degrees = rot
	mi.scale = escala
	padre.add_child(mi, true)
	return mi


static func node(padre: Node, nombre: String, pos := Vector3.ZERO, rot := Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	n.name = nombre
	n.position = pos
	n.rotation_degrees = rot
	padre.add_child(n, true)
	return n


static func marker(padre: Node, nombre: String, pos := Vector3.ZERO) -> Marker3D:
	var m := Marker3D.new()
	m.name = nombre
	m.position = pos
	padre.add_child(m, true)
	return m


## Cuerpo estático con una caja de colisión simple.
static func collision(padre: Node, centro: Vector3, tam: Vector3, nombre := "Colision") -> StaticBody3D:
	var body: StaticBody3D
	if padre is StaticBody3D and nombre == "":
		body = padre
	else:
		body = StaticBody3D.new()
		body.name = nombre
		padre.add_child(body, true)
	var shape := CollisionShape3D.new()
	shape.name = "Volumen"
	var box := BoxShape3D.new()
	box.size = tam
	shape.shape = box
	shape.position = centro
	body.add_child(shape, true)
	return body


## Luz ámbar con marco (plano XY, mira hacia +Z local).
static func led(padre: Node, nombre: String, pos: Vector3, ancho: float, alto: float, rot := Vector3.ZERO, color := "ambar") -> Node3D:
	var n := node(padre, nombre, pos, rot)
	var r := minf(ancho, alto) * 0.5
	part(n, "Marco", plate(ancho + 0.07, alto + 0.07, 0.05, r + 0.035, 0.012), "naranja_marco" if color.begins_with("ambar") else "turquesa_osc")
	part(n, "Luz", plate(ancho, alto, 0.05, r, 0.012), color, Vector3(0, 0, 0.018))
	return n


## Coloca un nodo sobre un cilindro: `ang` en grados desde +X hacia +Z, con +Z local hacia fuera.
static func on_ring(n: Node3D, ang: float, radio: float, y: float, inclinar: float = 0.0) -> void:
	var a := deg_to_rad(ang)
	n.position = Vector3(cos(a) * radio, y, sin(a) * radio)
	n.rotation = Vector3(deg_to_rad(-inclinar), atan2(cos(a), sin(a)), 0.0)


## Orienta un nodo para que su eje +Y apunte en `dir`.
static func aim_y(n: Node3D, dir: Vector3) -> void:
	var d := dir.normalized()
	var axis := Vector3.UP.cross(d)
	if axis.length() < 0.0001:
		n.basis = Basis.IDENTITY if d.y > 0.0 else Basis(Vector3.RIGHT, PI)
	else:
		n.basis = Basis(axis.normalized(), Vector3.UP.angle_to(d))


## Asigna dueño a todo el árbol para poder guardar la escena.
static func own(raiz: Node, n: Node = null) -> void:
	if n == null:
		n = raiz
	for child in n.get_children():
		child.owner = raiz
		# las escenas instanciadas se guardan como instancia, sin copiar su contenido
		if child.scene_file_path == "":
			own(raiz, child)


# ---------------------------------------------------------------- optimización

## Grupos de adorno que no se animan: sus mallas se funden con las del nodo padre.
const ESTATICOS := ["Ventanilla", "Hoja", "Pata", "Protector", "Deposito", "Control", "Camara", "Planta", "Eje",
	"Sensor", "Taco", "Parche", "Casco", "Antena", "Celda", "Cuchara", "Veta", "Base", "Crater", "Acople",
	"LuzPlataforma", "LuzFrontal", "LuzLateral", "LuzBandeja", "LuzTolva", "LuzTrasera", "LuzBase", "LuzCostado",
	"LuzTope", "IndicadorPata", "Marco"]
## Mallas que el juego mueve, oculta o anima por su nombre: nunca se funden.
const CONSERVAR := ["Gota", "Agua", "SuperficieHorizontal", "Segmento", "Brace", "Baliza", "LamparaAmbar", "Luz", "Burbuja"]


static func _sin_cifras(nombre: String) -> String:
	return nombre.rstrip("0123456789")


## Funde las mallas hermanas que comparten material para reducir las llamadas de dibujado.
## Respeta pivotes, marcadores, escenas instanciadas y las mallas de `CONSERVAR`.
static func fusionar(n: Node) -> void:
	for child in n.get_children():
		if child.scene_file_path == "":
			fusionar(child)
	for child in n.get_children():
		if child.get_class() != "Node3D" or child.get_script() != null or child.scene_file_path != "":
			continue
		if not _sin_cifras(child.name) in ESTATICOS:
			continue
		var grupo := child as Node3D
		if not grupo.scale.is_equal_approx(Vector3.ONE * grupo.scale.x):
			continue
		for g in grupo.get_children():
			if g is MeshInstance3D and g.get_child_count() == 0:
				var t: Transform3D = grupo.transform * (g as MeshInstance3D).transform
				grupo.remove_child(g)
				n.add_child(g, true)
				(g as MeshInstance3D).transform = t
		if grupo.get_child_count() == 0:
			n.remove_child(grupo)
			grupo.free()
	var grupos := {}
	for child in n.get_children():
		var mi := child as MeshInstance3D
		if mi == null or mi.get_child_count() > 0 or not mi.visible or mi.mesh == null:
			continue
		if _sin_cifras(mi.name) in CONSERVAR or not (mi.material_override is StandardMaterial3D):
			continue
		if not mi.scale.is_equal_approx(Vector3.ONE * mi.scale.x) or mi.mesh.get_surface_count() != 1:
			continue
		var formato := 1 if mi.mesh is ArrayMesh else 2
		if mi.mesh is ArrayMesh and ((mi.mesh as ArrayMesh).surface_get_format(0) & Mesh.ARRAY_FORMAT_COLOR) != 0:
			formato = 3
		var key := "%s|%d|%d" % [mi.material_override.resource_name, mi.cast_shadow, formato]
		if not grupos.has(key):
			grupos[key] = []
		grupos[key].append(mi)
	for key in grupos:
		var lista: Array = grupos[key]
		if lista.size() < 2:
			continue
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for mi in lista:
			st.append_from(mi.mesh, 0, mi.transform)
		st.index()
		var fundida := MeshInstance3D.new()
		fundida.name = "Malla_" + String(key).get_slice("|", 0)
		fundida.mesh = st.commit()
		fundida.material_override = lista[0].material_override
		fundida.cast_shadow = lista[0].cast_shadow
		n.add_child(fundida, true)
		for mi in lista:
			n.remove_child(mi)
			mi.free()
