extends CharacterBody3D
class_name GRBGEnemy

signal defeated(enemy: Node3D)

const MOVE_SPEED := 3.4
const GRAVITY := 18.0
const DETECT_RANGE := 48.0
const ATTACK_RANGE := 22.0
const ATTACK_INTERVAL := 1.25
const DAMAGE := 6
const RIG_SCRIPT = preload("res://scripts/soldier_rig.gd")

var target_player: Node3D
var health := 120
var attack_timer := 1.0
var label: Label3D
var vest_material: StandardMaterial3D
var soldier_rig: GRBGSoldierRig

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
	soldier_rig = RIG_SCRIPT.new()
	soldier_rig.name = "AnimatedEnemySoldier"
	add_child(soldier_rig)
	label = Label3D.new()
	label.text = "ENEMY 120 HP"
	label.position = Vector3(0, 2.35, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 28
	add_child(label)

func _process(_delta: float) -> void:
	if is_instance_valid(soldier_rig):
		soldier_rig.set_motion(Vector2(velocity.x, velocity.z).length() / MOVE_SPEED)

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
