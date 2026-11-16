extends Node3D

@onready var player: CharacterBody3D = $Player

func _ready() -> void:
    _build_mobile_hud()

func _build_mobile_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)

    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(root)

    var title := Label.new()
    title.text = "مغامرة المستقبل 3D"
    title.position = Vector2(24, 20)
    title.add_theme_font_size_override("font_size", 26)
    root.add_child(title)

    var hint := Label.new()
    hint.text = "تحرك واستكشف المرحلة — WASD أو أزرار اللمس"
    hint.position = Vector2(24, 58)
    hint.add_theme_font_size_override("font_size", 16)
    root.add_child(hint)

    var controls := HBoxContainer.new()
    controls.anchor_left = 1.0
    controls.anchor_top = 1.0
    controls.anchor_right = 1.0
    controls.anchor_bottom = 1.0
    controls.offset_left = -390
    controls.offset_top = -120
    controls.offset_right = -18
    controls.offset_bottom = -18
    controls.add_theme_constant_override("separation", 8)
    root.add_child(controls)

    _add_move_button(controls, "◀", Vector2.LEFT)
    _add_move_button(controls, "▲", Vector2.UP)
    _add_move_button(controls, "▼", Vector2.DOWN)
    _add_move_button(controls, "▶", Vector2.RIGHT)

    var jump := Button.new()
    jump.text = "قفز"
    jump.custom_minimum_size = Vector2(82, 82)
    jump.add_theme_font_size_override("font_size", 22)
    jump.button_down.connect(player.request_mobile_jump)
    controls.add_child(jump)

func _add_move_button(parent: HBoxContainer, caption: String, direction: Vector2) -> void:
    var button := Button.new()
    button.text = caption
    button.custom_minimum_size = Vector2(58, 82)
    button.add_theme_font_size_override("font_size", 24)
    button.button_down.connect(func(): player.set_mobile_move(direction))
    button.button_up.connect(func(): player.set_mobile_move(Vector2.ZERO))
    parent.add_child(button)
