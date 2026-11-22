extends Node3D
class_name GRBGSoldierRig

var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var rifle: Node3D
var muzzle: MeshInstance3D
var animation_clock := 0.0
var movement_speed := 0.0
var firing_flash := 0.0
var base_tint := Color(0.20, 0.29, 0.19)
var uniform_material: StandardMaterial3D
var weapon_index := 0

func _ready() -> void:
	_build_rig()

func _mat(color: Color, roughness: float = 0.78, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m

func _mesh(parent: Node3D, shape: Mesh, pos: Vector3, material: Material, scale_value: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = shape
	part.position = pos
	part.scale = scale_value
	part.material_override = material
	parent.add_child(part)
	return part

func _box(parent: Node3D, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return _mesh(parent, shape, pos, material)

func _capsule(parent: Node3D, pos: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var shape := CapsuleMesh.new()
	shape.radius = radius
	shape.height = height
	return _mesh(parent, shape, pos, material)

func _build_rig() -> void:
	var uniform := _mat(base_tint)
	uniform_material = uniform
	var dark := _mat(Color(0.055, 0.072, 0.065))
	var fabric := _mat(Color(0.31, 0.34, 0.25))
	var skin := _mat(Color(0.48, 0.31, 0.21))
	var metal := _mat(Color(0.075, 0.09, 0.085), 0.32, 0.72)
	var lens := _mat(Color(0.025, 0.055, 0.06), 0.18, 0.35)
	var boot_shape := BoxMesh.new()
	boot_shape.size = Vector3(0.30, 0.20, 0.43)
	_mesh(self, boot_shape, Vector3(-0.17, 0.10, -0.055), dark)
	_mesh(self, boot_shape, Vector3(0.17, 0.10, -0.055), dark)

	left_leg = Node3D.new()
	left_leg.position = Vector3(-0.17, 0.88, 0)
	add_child(left_leg)
	_capsule(left_leg, Vector3(0, -0.27, 0), 0.145, 0.72, uniform)
	_box(left_leg, Vector3(0, -0.12, -0.13), Vector3(0.22, 0.25, 0.07), fabric)
	right_leg = Node3D.new()
	right_leg.position = Vector3(0.17, 0.88, 0)
	add_child(right_leg)
	_capsule(right_leg, Vector3(0, -0.27, 0), 0.145, 0.72, uniform)
	_box(right_leg, Vector3(0, -0.12, -0.13), Vector3(0.22, 0.25, 0.07), fabric)

	_capsule(self, Vector3(0, 1.15, 0), 0.34, 0.76, uniform)
	_box(self, Vector3(0, 1.19, -0.015), Vector3(0.63, 0.55, 0.34), fabric)
	for x in [-0.20, 0.0, 0.20]:
		_box(self, Vector3(x, 1.17, -0.205), Vector3(0.14, 0.20, 0.035), uniform)
	_box(self, Vector3(0, 1.48, 0.22), Vector3(0.43, 0.48, 0.23), dark)
	_box(self, Vector3(-0.25, 1.40, 0.17), Vector3(0.12, 0.24, 0.12), fabric)
	_box(self, Vector3(0.25, 1.40, 0.17), Vector3(0.12, 0.24, 0.12), fabric)
	_capsule(self, Vector3(0, 1.76, 0), 0.19, 0.38, skin)
	var helmet := SphereMesh.new()
	helmet.radius = 0.235
	helmet.height = 0.22
	_mesh(self, helmet, Vector3(0, 1.94, 0.015), _mat(Color(0.12, 0.18, 0.12), 0.48))
	_box(self, Vector3(0, 1.86, -0.19), Vector3(0.31, 0.055, 0.045), dark)
	_box(self, Vector3(-0.105, 1.80, -0.18), Vector3(0.075, 0.045, 0.025), lens)
	_box(self, Vector3(0.105, 1.80, -0.18), Vector3(0.075, 0.045, 0.025), lens)
	_box(self, Vector3(0, 1.63, 0.22), Vector3(0.30, 0.08, 0.045), fabric)

	left_arm = Node3D.new()
	left_arm.position = Vector3(-0.39, 1.43, 0)
	add_child(left_arm)
	_capsule(left_arm, Vector3(0, -0.22, -0.015), 0.13, 0.55, uniform)
	_capsule(left_arm, Vector3(0, -0.54, -0.12), 0.105, 0.43, uniform)
	_capsule(left_arm, Vector3(0, -0.76, -0.17), 0.09, 0.16, dark)
	right_arm = Node3D.new()
	right_arm.position = Vector3(0.39, 1.43, 0)
	add_child(right_arm)
	_capsule(right_arm, Vector3(0, -0.22, -0.015), 0.13, 0.55, uniform)
	_capsule(right_arm, Vector3(0, -0.50, -0.16), 0.105, 0.43, uniform)
	_capsule(right_arm, Vector3(0, -0.70, -0.22), 0.09, 0.16, dark)

	rifle = Node3D.new()
	rifle.position = Vector3(0.30, 1.12, -0.36)
	add_child(rifle)
	_box(rifle, Vector3(0, 0, 0), Vector3(0.13, 0.13, 0.72), metal)
	_box(rifle, Vector3(0, -0.12, 0.10), Vector3(0.10, 0.20, 0.20), dark)
	_box(rifle, Vector3(0, 0.10, -0.05), Vector3(0.07, 0.08, 0.28), dark)
	var barrel := CylinderMesh.new()
	barrel.top_radius = 0.025
	barrel.bottom_radius = 0.025
	barrel.height = 0.35
	_mesh(rifle, barrel, Vector3(0, 0, -0.51), metal, Vector3.ONE)
	muzzle = _mesh(rifle, SphereMesh.new(), Vector3(0, 0, -0.72), _mat(Color(1.0, 0.55, 0.12), 0.2, 0.0))
	muzzle.scale = Vector3.ZERO

func set_motion(speed: float, aiming: bool = false, firing: bool = false) -> void:
	movement_speed = clampf(speed, 0.0, 1.0)
	if aiming:
		right_arm.rotation.x = lerpf(right_arm.rotation.x, -0.65, 0.22)
		left_arm.rotation.x = lerpf(left_arm.rotation.x, -0.45, 0.22)
	if firing:
		firing_flash = 0.07

func set_weapon(index: int) -> void:
	weapon_index = clampi(index, 0, 2)
	if is_instance_valid(rifle):
		match weapon_index:
			0:
				rifle.scale = Vector3.ONE
			1:
				rifle.scale = Vector3(0.82, 0.88, 0.78)
			2:
				rifle.scale = Vector3(1.12, 1.05, 1.18)

func set_uniform_tint(color: Color) -> void:
	base_tint = color
	if is_instance_valid(uniform_material):
		uniform_material.albedo_color = color

func _process(delta: float) -> void:
	animation_clock += delta
	var swing := sin(animation_clock * (8.5 if movement_speed > 0.12 else 2.0)) * movement_speed * 0.62
	left_leg.rotation.x = swing
	right_leg.rotation.x = -swing
	left_arm.rotation.x = -swing * 0.55
	right_arm.rotation.x = 0.0 if movement_speed < 0.12 else swing * 0.25
	if movement_speed > 0.12:
		position.y = absf(sin(animation_clock * 8.5)) * 0.035
	else:
		position.y = sin(animation_clock * 1.8) * 0.008
	if firing_flash > 0.0:
		firing_flash -= delta
		muzzle.scale = Vector3.ONE * (1.0 + randf() * 0.5)
	else:
		muzzle.scale = Vector3.ZERO
