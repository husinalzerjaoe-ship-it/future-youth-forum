extends CharacterBody3D

@export var move_speed: float = 5.5
@export var jump_velocity: float = 5.0
@export var gravity: float = 16.0

var _move_input := Vector2.ZERO

func set_mobile_move(value: Vector2) -> void:
    _move_input = value.limit_length(1.0)

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        if Input.is_action_just_pressed("jump"):
            velocity.y = jump_velocity

    var keyboard := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var input_dir := keyboard if keyboard.length() > 0.01 else _move_input
    var direction := Vector3(input_dir.x, 0.0, input_dir.y)
    direction = direction.rotated(Vector3.UP, 0.0).normalized()

    velocity.x = direction.x * move_speed
    velocity.z = direction.z * move_speed
    move_and_slide()
