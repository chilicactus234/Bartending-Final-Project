extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var speed: float = 180.0
var movement_locked: bool = false

signal navigation_finished

func _physics_process(_delta: float) -> void:
	if movement_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		_play_idle()
		return
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")
	if Input.is_key_pressed(KEY_W): direction.y -= 1
	if Input.is_key_pressed(KEY_S): direction.y += 1
	if Input.is_key_pressed(KEY_A): direction.x -= 1
	if Input.is_key_pressed(KEY_D): direction.x += 1
	
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		velocity = direction * speed
		move_and_slide()
		_play_walk(direction)
	else:
		velocity = Vector2.ZERO
		move_and_slide()
		_play_idle()

func _play_walk(direction: Vector2) -> void:
	if abs(direction.x) > abs(direction.y):
		anim.flip_h = direction.x < 0
		anim.play("walk_side")
	elif direction.y < 0:
		anim.flip_h = false
		anim.play("walk_up")
	else:
		anim.flip_h = false
		anim.play("walk_down")

func _play_idle() -> void:
	match anim.animation:
		"walk_side":
			anim.play("idle_side")
		"walk_up":
			anim.play("idle_up")
		"walk_down":
			anim.play("idle_down")
		_:
			if not anim.is_playing():
				anim.play("idle_down")
