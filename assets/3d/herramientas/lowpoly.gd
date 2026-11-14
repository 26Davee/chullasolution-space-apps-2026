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
	if nrm.length_squared() < 0.00000001:
		return
	if nrm.dot(hacia_fuera) > 0.0:
		var t := b
		b = c
		c = t
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
