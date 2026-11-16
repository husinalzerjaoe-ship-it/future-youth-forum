extends Node3D

@onready var player: CharacterBody3D = $Player

var _score := 0
var _total := 0
var _mode := "treasure"
var _score_label: Label
var _status_label: Label
var _level_root: Node3D

const MODES := {
    "treasure": "كنز الجزر",
    "runner": "سباق الحواجز",
    "targets": "صياد الأهداف"
}

func _ready() -> void:
    _level_root = Node3D.new()
    _level_root.name = "GeneratedLevel"
    add_child(_level_root)
    _build_mobile_hud()
    _load_mode("treasure")

func _build_mobile_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(root)

    var title := Label.new()
    title.text = "مغامرات المستقبل 3D"
    title.position = Vector2(20, 12)
    title.add_theme_font_size_override("font_size", 25)
    root.add_child(title)

    _score_label = Label.new()
    _score_label.position = Vector2(20, 48)
    _score_label.add_theme_font_size_override("font_size", 18)
    root.add_child(_score_label)

    _status_label = Label.new()
    _status_label.position = Vector2(20, 76)
    _status_label.add_theme_font_size_override("font_size", 15)
    root.add_child(_status_label)

    var modes := HBoxContainer.new()
    modes.position = Vector2(16, 112)
    modes.add_theme_constant_override("separation", 7)
    root.add_child(modes)
    _add_mode_button(modes, "كنز", "treasure")
    _add_mode_button(modes, "حواجز", "runner")
    _add_mode_button(modes, "أهداف", "targets")

    var controls := HBoxContainer.new()
    controls.anchor_left = 1.0
    controls.anchor_top = 1.0
    controls.anchor_right = 1.0
    controls.anchor_bottom = 1.0
    controls.offset_left = -390
    controls.offset_top = -112
    controls.offset_right = -14
    controls.offset_bottom = -14
    controls.add_theme_constant_override("separation", 7)
    root.add_child(controls)
    _add_move_button(controls, "◀", Vector2.LEFT)
    _add_move_button(controls, "▲", Vector2.UP)
    _add_move_button(controls, "▼", Vector2.DOWN)
    _add_move_button(controls, "▶", Vector2.RIGHT)

    var jump := Button.new()
    jump.text = "قفز"
    jump.custom_minimum_size = Vector2(76, 76)
    jump.add_theme_font_size_override("font_size", 20)
    jump.button_down.connect(player.request_mobile_jump)
    controls.add_child(jump)

func _add_mode_button(parent: HBoxContainer, caption: String, mode: String) -> void:
    var button := Button.new()
    button.text = caption
    button.custom_minimum_size = Vector2(90, 42)
    button.pressed.connect(func(): _load_mode(mode))
    parent.add_child(button)

func _add_move_button(parent: HBoxContainer, caption: String, direction: Vector2) -> void:
    var button := Button.new()
    button.text = caption
    button.custom_minimum_size = Vector2(54, 76)
    button.add_theme_font_size_override("font_size", 22)
    button.button_down.connect(func(): player.set_mobile_move(direction))
    button.button_up.connect(func(): player.set_mobile_move(Vector2.ZERO))
    parent.add_child(button)

func _load_mode(mode: String) -> void:
    _mode = mode
    _score = 0
    _level_root.queue_free()
    _level_root = Node3D.new()
    _level_root.name = "GeneratedLevel"
    add_child(_level_root)
    player.global_position = Vector3(0, 1.1, 7)
    player.velocity = Vector3.ZERO

    match _mode:
        "treasure":
            _build_treasure_level()
        "runner":
            _build_runner_level()
        "targets":
            _build_target_level()
    _update_score()
    _status_label.text = MODES[_mode] + " — اجمع كل العناصر!"

func _build_treasure_level() -> void:
    _total = 12
    for i in range(12):
        var x := float((i % 4) * 5 - 7)
        var z := float(-4 - int(i / 4) * 6)
        _add_pickup(Vector3(x, 1.0 + float(i % 3) * 0.4, z), Color(1.0, 0.78, 0.18), "جوهرة")

func _build_runner_level() -> void:
    _total = 8
    for i in range(8):
        var z := -3.0 - float(i) * 3.0
        var lane := [-3.0, 0.0, 3.0][i % 3]
        _add_box(Vector3(lane, 0.55, z), Vector3(1.6, 1.1, 1.2), Color(0.9, 0.25, 0.35))
        _add_pickup(Vector3(-lane, 1.0, z - 1.2), Color(0.25, 0.9, 0.85), "شارة")
    _total = 8
    _status_label.text = "اقفز فوق الحواجز واجمع الشارات"

func _build_target_level() -> void:
    _total = 10
    for i in range(10):
        var angle := TAU * float(i) / 10.0
        var position := Vector3(cos(angle) * 8.0, 1.2 + float(i % 3), -7.0 + sin(angle) * 5.0)
        _add_pickup(position, Color(0.35, 0.65, 1.0), "هدف")
    _status_label.text = "تحرك نحو الأهداف المضيئة واجمعها"

func _add_box(position: Vector3, size: Vector3, color: Color) -> void:
    var body := StaticBody3D.new()
    body.position = position
    _level_root.add_child(body)
    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = 0.25
    material.roughness = 0.35
    mesh_instance.material_override = material
    body.add_child(mesh_instance)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)

func _add_pickup(position: Vector3, color: Color, kind: String) -> void:
    var pickup := Area3D.new()
    pickup.position = position
    pickup.collision_layer = 0
    pickup.collision_mask = 1
    _level_root.add_child(pickup)

    var mesh_instance := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.42
    mesh.height = 0.84
    mesh_instance.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = 1.2
    mesh_instance.material_override = material
    pickup.add_child(mesh_instance)

    var collision := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = 0.8
    collision.shape = shape
    pickup.add_child(collision)
    pickup.body_entered.connect(_on_pickup_entered.bind(pickup, kind))

func _on_pickup_entered(body: Node3D, pickup: Area3D, kind: String) -> void:
    if body != player or not is_instance_valid(pickup):
        return
    _score += 1
    pickup.queue_free()
    _update_score()
    if _score >= _total:
        _status_label.text = "أحسنت! أكملت " + MODES[_mode] + " 🏆"

func _update_score() -> void:
    _score_label.text = "النقاط: %d / %d" % [_score, _total]
