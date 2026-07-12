class_name DicePresentation3D
extends SubViewportContainer

enum DieState { READY, ROLLING, SETTLING, LOCKED }

const MAX_DICE := 5
const VIEWPORT_SIZE := Vector2i(640, 280)
const DIE_BASE_Y := 0.82
const SETTLE_DURATION := 0.18
const IVORY := Color("#fff4dc")
const PIP_COLOR := Color("#352b24")
const GOLD := Color("#c99b43")

var viewport: SubViewport
var world_root: Node3D
var camera: Camera3D
var dice_roots: Array[Node3D] = []
var cube_materials: Array[StandardMaterial3D] = []
var die_states: Array[int] = []
var face_values: Array[int] = []
var settle_elapsed: Array[float] = []
var roll_elapsed: Array[float] = []
var base_positions: Array[Vector3] = []
var settle_start_positions: Array[Vector3] = []
var settle_start_rotations: Array[Vector3] = []
var active_count := 0
var next_lock_index := -1
var animation_time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, 176)
	stretch = true
	_build_world()
	set_process(true)

func _build_world() -> void:
	viewport = SubViewport.new()
	viewport.name = "DiceSubViewport"
	viewport.size = VIEWPORT_SIZE
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	world_root = Node3D.new(); world_root.name = "DiceWorld"; viewport.add_child(world_root)

	var environment := WorldEnvironment.new(); environment.name = "WarmEnvironment"
	var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0, 0, 0, 0); env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color("#d7e0dd"); env.ambient_light_energy = 0.36
	environment.environment = env; world_root.add_child(environment)

	camera = Camera3D.new(); camera.name = "DiceCamera"; camera.fov = 30.0; camera.position = Vector3(0, 6.2, 9.8); camera.look_at_from_position(camera.position, Vector3(0, 0.42, 0)); world_root.add_child(camera)
	var key := DirectionalLight3D.new(); key.name = "WarmKey"; key.light_color = Color("#ffe1ad"); key.light_energy = 1.02; key.shadow_enabled = true; key.rotation_degrees = Vector3(-52, -28, 0); world_root.add_child(key)
	var fill := OmniLight3D.new(); fill.name = "SoftFill"; fill.light_color = Color("#bcd9dc"); fill.light_energy = 0.45; fill.omni_range = 12.0; fill.position = Vector3(-4, 4, 5); world_root.add_child(fill)

	var tray := MeshInstance3D.new(); tray.name = "SoftShadowTray"
	var tray_mesh := PlaneMesh.new(); tray_mesh.size = Vector2(10.5, 5.4); tray.mesh = tray_mesh
	var tray_material := StandardMaterial3D.new(); tray_material.albedo_color = Color("#806c4e"); tray_material.roughness = 0.96; tray.material_override = tray_material
	tray.position = Vector3(0, -0.02, 0); world_root.add_child(tray)
	for index: int in range(MAX_DICE): _build_die(index)

func _build_die(index: int) -> void:
	var die := Node3D.new(); die.name = "Die3D_%d" % index; die.visible = false; world_root.add_child(die)
	var cube := MeshInstance3D.new(); cube.name = "IvoryCube"
	var box := BoxMesh.new(); box.size = Vector3(1.42, 1.42, 1.42); cube.mesh = box
	var material := StandardMaterial3D.new(); material.albedo_color = IVORY; material.roughness = 0.62; material.metallic = 0.02
	cube.material_override = material; cube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON; die.add_child(cube)
	cube_materials.append(material)
	var pip_transforms: Array[Transform3D] = []
	_collect_face_pips(pip_transforms, 1, Vector3.UP, Vector3.RIGHT, Vector3.BACK)
	_collect_face_pips(pip_transforms, 6, Vector3.DOWN, Vector3.RIGHT, Vector3.FORWARD)
	_collect_face_pips(pip_transforms, 2, Vector3.BACK, Vector3.RIGHT, Vector3.UP)
	_collect_face_pips(pip_transforms, 5, Vector3.FORWARD, Vector3.LEFT, Vector3.UP)
	_collect_face_pips(pip_transforms, 3, Vector3.RIGHT, Vector3.FORWARD, Vector3.UP)
	_collect_face_pips(pip_transforms, 4, Vector3.LEFT, Vector3.BACK, Vector3.UP)
	var pips := MultiMeshInstance3D.new(); pips.name = "SixFacePips"
	var multi := MultiMesh.new(); multi.transform_format = MultiMesh.TRANSFORM_3D; multi.instance_count = pip_transforms.size()
	var pip_mesh := CylinderMesh.new(); pip_mesh.top_radius = 0.105; pip_mesh.bottom_radius = 0.105; pip_mesh.height = 0.045; pip_mesh.radial_segments = 12; multi.mesh = pip_mesh
	for pip_index: int in range(pip_transforms.size()): multi.set_instance_transform(pip_index, pip_transforms[pip_index])
	var pip_material := StandardMaterial3D.new(); pip_material.albedo_color = PIP_COLOR; pip_material.roughness = 0.78
	pips.multimesh = multi; pips.material_override = pip_material; die.add_child(pips)
	dice_roots.append(die); die_states.append(DieState.READY); face_values.append(1); settle_elapsed.append(SETTLE_DURATION); roll_elapsed.append(0.0); base_positions.append(Vector3.ZERO); settle_start_positions.append(Vector3.ZERO); settle_start_rotations.append(Vector3.ZERO)

func _collect_face_pips(transforms: Array[Transform3D], value: int, normal: Vector3, horizontal: Vector3, vertical: Vector3) -> void:
	var patterns: Array = [[], [Vector2.ZERO], [Vector2(-1, -1), Vector2(1, 1)], [Vector2(-1, -1), Vector2.ZERO, Vector2(1, 1)], [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)], [Vector2(-1, -1), Vector2(1, -1), Vector2.ZERO, Vector2(-1, 1), Vector2(1, 1)], [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(1, 0), Vector2(-1, 1), Vector2(1, 1)]]
	for pip_index: int in range(patterns[value].size()):
		var coordinate: Vector2 = patterns[value][pip_index]
		var position := normal * 0.735 + horizontal * coordinate.x * 0.31 + vertical * coordinate.y * 0.31
		transforms.append(Transform3D(Basis(Quaternion(Vector3.UP, normal)), position))

static func orientation_for_face(value: int) -> Vector3:
	match clampi(value, 1, 6):
		1: return Vector3.ZERO
		2: return Vector3(-PI * 0.5, 0, 0)
		3: return Vector3(0, 0, PI * 0.5)
		4: return Vector3(0, 0, -PI * 0.5)
		5: return Vector3(PI * 0.5, 0, 0)
		6: return Vector3(PI, 0, 0)
	return Vector3.ZERO

static func layout_for_count(count: int) -> Array[Vector3]:
	match clampi(count, 1, 5):
		1: return [Vector3(0, DIE_BASE_Y, 0)]
		2: return [Vector3(-1.25, DIE_BASE_Y, 0), Vector3(1.25, DIE_BASE_Y, 0)]
		3: return [Vector3(-2.25, DIE_BASE_Y, 0), Vector3(0, DIE_BASE_Y, 0), Vector3(2.25, DIE_BASE_Y, 0)]
		4: return [Vector3(-1.3, DIE_BASE_Y, -0.9), Vector3(1.3, DIE_BASE_Y, -0.9), Vector3(-1.3, DIE_BASE_Y, 1.05), Vector3(1.3, DIE_BASE_Y, 1.05)]
		5: return [Vector3(-2.15, DIE_BASE_Y, -0.85), Vector3(0, DIE_BASE_Y, -0.85), Vector3(2.15, DIE_BASE_Y, -0.85), Vector3(-1.1, DIE_BASE_Y, 1.05), Vector3(1.1, DIE_BASE_Y, 1.05)]
	return []

static func throw_offset(progress: float, dice_index: int) -> Vector3:
	var t := clampf(progress, 0.0, 1.0)
	var lane := sin(float(dice_index) * 1.7 + 0.4) * 0.24 * (1.0 - t)
	var forward := lerpf(1.55, -0.12, t)
	var main_arc := sin(t * PI) * 1.18
	var small_bounce := absf(sin(t * PI * 3.0)) * 0.14 * (1.0 - t)
	return Vector3(lane, main_arc + small_bounce, forward)

func present(values: Array[int], rolling: bool, locked_count: int) -> void:
	active_count = mini(MAX_DICE, values.size())
	var layout := layout_for_count(maxi(1, active_count))
	next_lock_index = clampi(locked_count, 0, active_count - 1) if rolling and locked_count < active_count else -1
	for index: int in range(MAX_DICE):
		var die := dice_roots[index]
		die.visible = index < active_count
		if index >= active_count: continue
		base_positions[index] = layout[index]
		var new_value := clampi(values[index], 1, 6)
		face_values[index] = new_value
		if rolling and index >= locked_count:
			if die_states[index] != DieState.ROLLING: roll_elapsed[index] = 0.0
			die_states[index] = DieState.ROLLING
		elif die_states[index] == DieState.ROLLING:
			die_states[index] = DieState.SETTLING; settle_elapsed[index] = 0.0; settle_start_positions[index] = die.position; settle_start_rotations[index] = die.rotation
		elif not rolling and die_states[index] != DieState.SETTLING:
			die_states[index] = DieState.READY
		cube_materials[index].emission_enabled = index == next_lock_index
		cube_materials[index].emission = GOLD
		cube_materials[index].emission_energy_multiplier = 0.17 if index == next_lock_index else 0.0
	queue_redraw()

func _process(delta: float) -> void:
	animation_time += delta
	for index: int in range(active_count):
		var die := dice_roots[index]
		match die_states[index]:
			DieState.ROLLING:
				roll_elapsed[index] += delta
				die.rotation += Vector3(7.8 + index * 0.3, 9.6 + index * 0.4, 5.2) * delta
				var throw_progress := clampf(roll_elapsed[index] / (0.78 + float(index) * 0.035), 0.0, 1.0)
				var residual_roll := Vector3(sin(animation_time * 7.0 + index) * 0.08, absf(sin(animation_time * 9.0 + index * 0.8)) * 0.12, 0)
				die.position = base_positions[index] + throw_offset(throw_progress, index) + residual_roll * (1.0 - throw_progress * 0.7)
			DieState.SETTLING:
				settle_elapsed[index] += delta
				var t := clampf(settle_elapsed[index] / SETTLE_DURATION, 0.0, 1.0)
				var eased := 1.0 - pow(1.0 - t, 3.0)
				die.rotation = settle_start_rotations[index].lerp(orientation_for_face(face_values[index]), eased) + Vector3(0, 0, sin(t * PI) * 0.12 * (1.0 - t))
				die.position = settle_start_positions[index].lerp(base_positions[index], eased) + Vector3(0, sin(t * PI) * 0.16, 0)
				if t >= 1.0: die_states[index] = DieState.LOCKED
			_:
				die.rotation = orientation_for_face(face_values[index])
				die.position = base_positions[index]
		var highlighted := index == next_lock_index
		var base_scale := 1.48 if active_count == 1 else 1.24
		die.scale = Vector3.ONE * (base_scale + 0.07 if highlighted else base_scale)

func state_name(index: int) -> String:
	if index < 0 or index >= die_states.size(): return "HIDDEN"
	return DieState.keys()[die_states[index]]

func pool_receipt() -> Dictionary:
	return {"viewport_size": viewport.size if viewport != null else Vector2i.ZERO, "pool_size": dice_roots.size(), "active_count": active_count, "root_child_count": world_root.get_child_count() if world_root != null else 0}
