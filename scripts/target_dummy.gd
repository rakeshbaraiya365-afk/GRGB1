extends StaticBody3D
class_name GRBGTargetDummy

signal destroyed(target: Node3D)

var health := 100
var label: Label3D

func _ready() -> void:
	_build_target()

func _build_target() -> void:
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.48
	shape.height = 1.9
	collision.shape = shape
	collision.position.y = 0.95
	add_child(collision)

	var mesh_instance := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.48
	mesh.height = 1.9
	mesh_instance.mesh = mesh
	mesh_instance.position.y = 0.95
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.72, 0.18, 0.12)
	material.roughness = 0.8
	mesh_instance.material_override = material
	add_child(mesh_instance)

	label = Label3D.new()
	label.text = "TARGET 100 HP"
	label.position = Vector3(0, 2.25, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 32
	add_child(label)

func apply_damage(amount: int) -> void:
	health = maxi(health - amount, 0)
	if is_instance_valid(label):
		label.text = "TARGET %d HP" % health
	if health <= 0:
		destroyed.emit(self)
		queue_free()
