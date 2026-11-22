extends Node3D
class_name GRBGIslandMap

const LAND := Color(0.28, 0.34, 0.22)
const SAND := Color(0.72, 0.61, 0.40)
const CONCRETE := Color(0.34, 0.36, 0.34)
const WOOD := Color(0.30, 0.19, 0.11)

func _ready() -> void:
	_build_terrain()
	_build_coast_and_roads()
	_build_landmarks()
	_build_cover()
	_build_vegetation()

func _material(color: Color, roughness: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m

func _static_box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, collidable: bool = true) -> void:
	var body: Node3D
	if collidable:
		body = StaticBody3D.new()
	else:
		body = Node3D.new()
	body.position = pos
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = _material(color)
	mesh.position.y = size.y * 0.5
	body.add_child(mesh)
	if collidable:
		var collision := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		collision.shape = box
		collision.position.y = size.y * 0.5
		body.add_child(collision)
	parent.add_child(body)

func _build_terrain() -> void:
	var ocean := MeshInstance3D.new()
	var sea := PlaneMesh.new()
	sea.size = Vector2(260, 260)
	ocean.mesh = sea
	var water := _material(Color(0.025, 0.19, 0.25), 0.22)
	water.metallic = 0.18
	ocean.material_override = water
	ocean.position.y = -0.48
	add_child(ocean)

	var ground := StaticBody3D.new()
	ground.name = "IslandTerrain"
	var land_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(110, 110)
	land_mesh.mesh = plane
	land_mesh.material_override = _material(LAND)
	ground.add_child(land_mesh)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(110, 0.6, 110)
	collision.shape = box
	collision.position.y = -0.30
	ground.add_child(collision)
	add_child(ground)

func _build_coast_and_roads() -> void:
	for i in range(28):
		var angle := TAU * float(i) / 28.0
		var radius := 51.0 + sin(float(i) * 1.7) * 2.2
		var pebble := SphereMesh.new()
		pebble.radius = 1.0
		pebble.height = 0.5
		var stone := MeshInstance3D.new()
		stone.mesh = pebble
		stone.scale = Vector3(3.2, 0.22, 2.4)
		stone.position = Vector3(cos(angle) * radius, -0.12, sin(angle) * radius)
		stone.material_override = _material(SAND)
		add_child(stone)
	for z in [-38.0, -25.0, -12.0, 2.0, 16.0, 30.0]:
		var road := MeshInstance3D.new()
		var road_mesh := BoxMesh.new()
		road_mesh.size = Vector3(3.4, 0.035, 10.0)
		road.mesh = road_mesh
		road.material_override = _material(Color(0.25, 0.25, 0.22))
		road.position = Vector3(0, 0.018, z)
		add_child(road)
	for x in [-1.1, 1.1]:
		var stripe := MeshInstance3D.new()
		var stripe_mesh := BoxMesh.new()
		stripe_mesh.size = Vector3(0.06, 0.04, 110.0)
		stripe.mesh = stripe_mesh
		stripe.material_override = _material(Color(0.82, 0.72, 0.46))
		stripe.position.x = x
		stripe.position.y = 0.04
		add_child(stripe)

func _building(pos: Vector3, size: Vector3, wall: Color, roof: Color, title: String) -> void:
	var building := StaticBody3D.new()
	building.position = pos
	var walls := MeshInstance3D.new()
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = size
	walls.mesh = wall_mesh
	walls.position.y = size.y * 0.5
	walls.material_override = _material(wall)
	building.add_child(walls)
	var roof_mesh := BoxMesh.new()
	roof_mesh.size = Vector3(size.x + 0.5, 0.22, size.z + 0.5)
	var roof_node := MeshInstance3D.new()
	roof_node.mesh = roof_mesh
	roof_node.position.y = size.y + 0.11
	roof_node.material_override = _material(roof)
	building.add_child(roof_node)
	var collision := CollisionShape3D.new()
	var collider := BoxShape3D.new()
	collider.size = size
	collision.shape = collider
	collision.position.y = size.y * 0.5
	building.add_child(collision)
	var sign := Label3D.new()
	sign.text = title
	sign.position = Vector3(0, size.y + 1.2, -size.z * 0.5 - 0.1)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.font_size = 28
	building.add_child(sign)
	add_child(building)
	_static_box(self, pos + Vector3(0, 0, size.z * 0.5 + 0.18), Vector3(1.2, 1.65, 0.22), Color(0.19, 0.12, 0.075), false)

func _build_landmarks() -> void:
	# Mahuva docks: warehouse, pier, containers and crane frame.
	_building(Vector3(-24, 0, -23), Vector3(10, 5, 8), Color(0.48, 0.40, 0.29), Color(0.22, 0.25, 0.25), "MAHUVA DOCKS")
	for i in range(3):
		_static_box(self, Vector3(-33 + i * 3.1, 0, -12), Vector3(2.7, 2.6, 2.2), [Color(0.58,0.22,0.12), Color(0.15,0.32,0.42), Color(0.62,0.49,0.16)][i])
	_static_box(self, Vector3(-37, 0, -5), Vector3(2.5, 0.55, 14), WOOD)
	_static_box(self, Vector3(-39, 0, -5), Vector3(0.22, 3.6, 0.22), Color(0.17,0.18,0.17))
	_static_box(self, Vector3(-35, 0, -5), Vector3(0.22, 3.6, 0.22), Color(0.17,0.18,0.17))
	_static_box(self, Vector3(-37, 3.5, -5), Vector3(4.2, 0.22, 0.22), Color(0.17,0.18,0.17))

	# Saurashtra village compound with multiple houses and a water tank.
	_building(Vector3(23, 0, -24), Vector3(8, 4, 7), Color(0.61,0.49,0.34), Color(0.32,0.20,0.12), "SAURASHTRA VILLAGE")
	_building(Vector3(32, 0, -15), Vector3(6, 3.5, 6), Color(0.56,0.48,0.36), Color(0.25,0.22,0.17), "VILLAGE EAST")
	_building(Vector3(18, 0, -10), Vector3(5, 3.2, 5), Color(0.58,0.53,0.40), Color(0.30,0.24,0.17), "OLD QUARTER")
	_static_box(self, Vector3(29, 0, -31), Vector3(1.4, 5.2, 1.4), Color(0.42,0.47,0.46))
	var tank := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.1
	cylinder.bottom_radius = 1.1
	cylinder.height = 1.2
	tank.mesh = cylinder
	tank.position = Vector3(29, 5.8, -31)
	tank.material_override = _material(Color(0.48,0.56,0.57), 0.4)
	add_child(tank)

	# Coastal outpost and watch tower.
	_building(Vector3(0, 0, -43), Vector3(13, 4, 7), Color(0.34,0.41,0.43), Color(0.18,0.23,0.25), "COASTAL OUTPOST")
	_static_box(self, Vector3(0, 0, -33), Vector3(1.4, 7.5, 1.4), Color(0.25,0.29,0.27))
	_static_box(self, Vector3(0, 7.5, -33), Vector3(3.5, 0.22, 3.5), Color(0.18,0.22,0.20))
	_static_box(self, Vector3(0, 8.2, -33), Vector3(0.22, 1.1, 0.22), Color(0.85,0.35,0.13))
	for x in [-5.0, 5.0]:
		_static_box(self, Vector3(x, 0, -37), Vector3(0.22, 2.6, 0.22), Color(0.17,0.19,0.18))

func _build_cover() -> void:
	var positions := [
		Vector3(-13,0,-9), Vector3(13,0,-9), Vector3(-13,0,-23), Vector3(13,0,-23),
		Vector3(-6,0,-34), Vector3(7,0,-35), Vector3(-19,0,-17), Vector3(19,0,-17),
		Vector3(-27,0,2), Vector3(27,0,2), Vector3(-30,0,-36), Vector3(30,0,-36),
		Vector3(-8,0,15), Vector3(9,0,19), Vector3(-22,0,23), Vector3(23,0,24)
	]
	for p in positions:
		_static_box(self, p, Vector3(2.8, 1.55, 2.8), Color(0.34,0.37,0.32))
	for i in range(10):
		var x := -25.0 + float(i) * 5.5
		_static_box(self, Vector3(x, 0, 9), Vector3(2.1, 1.1, 0.7), Color(0.38,0.31,0.22))

func _build_vegetation() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7241
	for i in range(34):
		var x := rng.randf_range(-45.0, 45.0)
		var z := rng.randf_range(-45.0, 45.0)
		if Vector2(x, z).length() > 48.0 or (absf(x) < 7.0 and z > -35.0 and z < 24.0):
			continue
		var trunk := MeshInstance3D.new()
		var trunk_mesh := CylinderMesh.new()
		trunk_mesh.top_radius = 0.12
		trunk_mesh.bottom_radius = 0.20
		trunk_mesh.height = 1.8
		trunk.mesh = trunk_mesh
		trunk.position = Vector3(x, 0.9, z)
		trunk.material_override = _material(Color(0.25,0.16,0.09))
		add_child(trunk)
		var crown := MeshInstance3D.new()
		var crown_mesh := SphereMesh.new()
		crown_mesh.radius = rng.randf_range(1.0, 1.55)
		crown_mesh.height = crown_mesh.radius * 1.45
		crown.mesh = crown_mesh
		crown.position = Vector3(x, 2.25, z)
		crown.material_override = _material(Color(0.13, rng.randf_range(0.23,0.34), 0.15))
		add_child(crown)
	for i in range(24):
		var rock := MeshInstance3D.new()
		var rock_mesh := SphereMesh.new()
		rock_mesh.radius = rng.randf_range(0.35, 0.9)
		rock_mesh.height = rock_mesh.radius * 0.8
		rock.mesh = rock_mesh
		rock.scale = Vector3(1.4, 0.7, 1.0)
		rock.position = Vector3(rng.randf_range(-48,48), 0.18, rng.randf_range(-48,48))
		rock.material_override = _material(Color(0.36,0.36,0.31))
		add_child(rock)
