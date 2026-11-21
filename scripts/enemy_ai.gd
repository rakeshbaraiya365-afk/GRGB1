extends CharacterBody3D
class_name GRBGEnemy

signal defeated(enemy: Node3D)

const MOVE_SPEED := 3.4
const GRAVITY := 18.0
const DETECT_RANGE := 48.0
const ATTACK_RANGE := 22.0
const ATTACK_INTERVAL := 1.25
const DAMAGE := 6

var target_player: Node3D
var health := 120
var attack_timer := 1.0
var label: Label3D
var vest_material: StandardMaterial3D

func _ready() -> void:
	_build_collision()
	_build_soldier_model()

func _build_collision() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.40
	capsule.height = 1.85
	collision.shape = capsule
	collision.position.y = 0.93
	add_child(collision)

func _material(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	material.metallic = metallic
	return material

func _part(mesh: Mesh, position: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO, scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position
	instance.rotation = rotation
	instance.scale = scale
	instance.material_override = material
	add_child(instance)
	return instance

func _capsule(radius: float, height: float, position: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO) -> void:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	_part(mesh, position, material, rotation)

func _build_soldier_model() -> void:
	var uniform := _material(Color(0.20, 0.27, 0.18))
	var dark := _material(Color(0.075, 0.09, 0.075))
	var skin := _material(Color(0.55, 0.36, 0.24))
	var helmet_mat := _material(Color(0.13, 0.19, 0.13), 0.08)
	vest_material = _material(Color(0.30, 0.34, 0.22))
	var metal := _material(Color(0.10, 0.12, 0.12), 0.55)

	var boot_mesh := BoxMesh.new()
	boot_mesh.size = Vector3(0.34, 0.20, 0.48)
	_part(boot_mesh, Vector3(-0.17, 0.12, -0.04), dark)
	_part(boot_mesh, Vector3(0.17, 0.12, -0.04), dark)
	_capsule(0.16, 0.78, Vector3(-0.17, 0.48, 0), uniform)
	_capsule(0.16, 0.78, Vector3(0.17, 0.48, 0), uniform)
	_capsule(0.34, 0.92, Vector3(0, 1.15, 0), uniform)

	var vest := BoxMesh.new()
	vest.size = Vector3(0.62, 0.60, 0.30)
	_part(vest, Vector3(0, 1.22, -0.04), vest_material)
	var shoulder := SphereMesh.new()
	shoulder.radius = 0.19
	shoulder.height = 0.36
	_part(shoulder, Vector3(-0.39, 1.43, 0), uniform)
	_part(shoulder, Vector3(0.39, 1.43, 0), uniform)
	_capsule(0.13, 0.72, Vector3(-0.43, 1.17, -0.03), uniform, Vector3(0, 0, -0.22))
	_capsule(0.13, 0.72, Vector3(0.43, 1.17, -0.18), uniform, Vector3(0, 0, 0.22))

	var glove := SphereMesh.new()
	glove.radius = 0.13
	glove.height = 0.22
	_part(glove, Vector3(-0.48, 0.82, -0.10), dark)
	_part(glove, Vector3(0.48, 0.84, -0.30), dark)
	var head := SphereMesh.new()
	head.radius = 0.22
	head.height = 0.43
	_part(head, Vector3(0, 1.83, 0), skin)
	var helmet := SphereMesh.new()
	helmet.radius = 0.25
	helmet.height = 0.25
	_part(helmet, Vector3(0, 2.00, 0.015), helmet_mat)
	var visor := BoxMesh.new()
	visor.size = Vector3(0.30, 0.055, 0.10)
	_part(visor, Vector3(0, 1.88, -0.19), dark)
	var pack := BoxMesh.new()
	pack.size = Vector3(0.40, 0.58, 0.22)
	_part(pack, Vector3(0, 1.23, 0.24), dark)
	var rifle := BoxMesh.new()
	rifle.size = Vector3(0.13, 0.14, 0.82)
	_part(rifle, Vector3(0.38, 1.23, -0.48), metal, Vector3(0, 0, -0.10))
	var barrel := CylinderMesh.new()
	barrel.top_radius = 0.035
	barrel.bottom_radius = 0.035
	barrel.height = 0.50
	_part(barrel, Vector3(0.38, 1.23, -1.10), metal, Vector3(PI / 2.0, 0, 0))
	var stock := BoxMesh.new()
	stock.size = Vector3(0.15, 0.19, 0.22)
	_part(stock, Vector3(0.38, 1.23, -0.05), dark)

	label = Label3D.new()
	label.text = "ENEMY 120 HP"
	label.position = Vector3(0, 2.35, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 28
	add_child(label)

func _physics_process(delta: float) -> void:
	if target_player == null or not is_instance_valid(target_player) or target_player.get("health") <= 0:
		velocity.x = move_toward(velocity.x, 0.0, MOVE_SPEED * delta)
		velocity.z = move_toward(velocity.z, 0.0, MOVE_SPEED * delta)
		_apply_gravity(delta)
		move_and_slide()
		return

	attack_timer = maxf(attack_timer - delta, 0.0)
	var offset := target_player.global_position - global_position
	var flat_offset := Vector3(offset.x, 0.0, offset.z)
	var distance := flat_offset.length()
	if distance <= DETECT_RANGE:
		var direction := flat_offset.normalized()
		if distance > 2.2:
			var look_query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, global_position + Vector3.UP + direction * 2.5)
			look_query.exclude = [get_rid()]
			var obstacle := get_world_3d().direct_space_state.intersect_ray(look_query)
			if not obstacle.is_empty() and obstacle.get("collider") != target_player:
				var side := -1.0 if int(get_instance_id()) % 2 == 0 else 1.0
				direction = direction.rotated(Vector3.UP, side * PI / 2.6)
			velocity.x = direction.x * MOVE_SPEED
			velocity.z = direction.z * MOVE_SPEED
		else:
			velocity.x = move_toward(velocity.x, 0.0, MOVE_SPEED * 4.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, MOVE_SPEED * 4.0 * delta)
		if distance > 0.1:
			look_at(Vector3(target_player.global_position.x, global_position.y, target_player.global_position.z), Vector3.UP)
		if distance <= ATTACK_RANGE and attack_timer <= 0.0:
			_try_attack()
			attack_timer = ATTACK_INTERVAL
	else:
		velocity.x = move_toward(velocity.x, 0.0, MOVE_SPEED * delta)
		velocity.z = move_toward(velocity.z, 0.0, MOVE_SPEED * delta)
	_apply_gravity(delta)
	move_and_slide()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

func _try_attack() -> void:
	var from := global_position + Vector3(0, 1.55, 0)
	var to := target_player.global_position + Vector3(0, 1.25, 0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.get("collider") == target_player:
		target_player.take_damage(DAMAGE)

func apply_damage(amount: int) -> void:
	health = maxi(health - amount, 0)
	if is_instance_valid(label):
		label.text = "ENEMY %d HP" % health
	if health <= 0:
		set_physics_process(false)
		defeated.emit(self)
		queue_free()
