extends CharacterBody3D

@export var move_speed: float = 6.0
@export var jump_velocity: float = 6.0
@export var gravity: float = 17.0

var _move_input := Vector2.ZERO
var _mobile_jump_requested := false

func _ready() -> void:
    _register_input("move_left", KEY_A)
    _register_input("move_right", KEY_D)
    _register_input("move_forward", KEY_W)
    _register_input("move_back", KEY_S)
    _register_input("jump", KEY_SPACE)

func _register_input(action_name: String, key: Key) -> void:
    if not InputMap.has_action(action_name):
        InputMap.add_action(action_name)
    var event := InputEventKey.new()
    event.physical_keycode = key
    InputMap.action_add_event(action_name, event)

func set_mobile_move(value: Vector2) -> void:
    _move_input = value.limit_length(1.0)

func request_mobile_jump() -> void:
    _mobile_jump_requested = true

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta
    elif Input.is_action_just_pressed("jump") or _mobile_jump_requested:
        velocity.y = jump_velocity
    _mobile_jump_requested = false

    var keyboard := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var input_dir := keyboard if keyboard.length() > 0.01 else _move_input
    velocity.x = input_dir.x * move_speed
    velocity.z = input_dir.y * move_speed
    move_and_slide()
