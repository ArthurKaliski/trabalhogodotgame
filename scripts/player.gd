extends CharacterBody2D

enum PlayerState {
	idle,
	walk,
	jump,
	fall,
	duck,
	slide,
	dead
}

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@export var max_speed = 150.0
@export var acceleration = 400.0
@export var deceleration = 400.0
@export var slide_deceleration = 100.0

@export var max_jump_count = 2
const JUMP_VELOCITY = -250.0
const GRAVITY = 980.0

var jump_count = 0
var direction = 0
var status: PlayerState

func _ready() -> void:
	go_to_idle_state()

func _physics_process(delta: float) -> void:
	# Se cair fora do mundo
	if global_position.y > 500:
		go_to_dead_state()
		return

	# Gravidade
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0

	match status:
		PlayerState.idle:
			idle_state(delta)
		PlayerState.walk:
			walk_state(delta)
		PlayerState.jump:
			jump_state(delta)
		PlayerState.fall:
			fall_state(delta)
		PlayerState.duck:
			duck_state(delta)
		PlayerState.slide:
			slide_state(delta)
		PlayerState.dead:
			dead_state(delta)

	move_and_slide()

# =========================
# Estados
# =========================

func idle_state(delta):
	move(delta)

	if velocity.x != 0:
		go_to_walk_state()

	elif Input.is_action_just_pressed("jump"):
		go_to_jump_state()

	elif Input.is_action_pressed("duck"):
		go_to_duck_state()


func walk_state(delta):
	move(delta)

	if velocity.x == 0:
		go_to_idle_state()

	elif Input.is_action_just_pressed("jump"):
		go_to_jump_state()

	elif Input.is_action_just_pressed("duck"):
		go_to_slide_state()

	elif not is_on_floor():
		jump_count += 1
		go_to_fall_state()


func jump_state(delta):
	move(delta)

	if Input.is_action_just_pressed("jump") and can_jump():
		go_to_jump_state()

	elif velocity.y > 0:
		go_to_fall_state()


func fall_state(delta):
	move(delta)

	if Input.is_action_just_pressed("jump") and can_jump():
		go_to_jump_state()

	elif is_on_floor():
		jump_count = 0
		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()


func duck_state(_delta):
	update_direction()

	if Input.is_action_just_released("duck"):
		exit_from_duck_state()
		go_to_idle_state()


func slide_state(delta):
	velocity.x = move_toward(velocity.x, 0, slide_deceleration * delta)

	if Input.is_action_just_released("duck"):
		exit_from_slide_state()
		go_to_walk_state()

	elif velocity.x == 0:
		exit_from_slide_state()
		go_to_duck_state()


func dead_state(_delta):
	pass  # Já é tratado dentro do próprio go_to_dead_state()

# =========================
# Transições de estado
# =========================

func go_to_idle_state():
	status = PlayerState.idle
	anim.play("idle")
	set_large_collider()

func go_to_walk_state():
	status = PlayerState.walk
	anim.play("walk")
	set_large_collider()

func go_to_jump_state():
	status = PlayerState.jump
	anim.play("jump")
	velocity.y = JUMP_VELOCITY
	jump_count += 1
	set_large_collider()

func go_to_fall_state():
	status = PlayerState.fall
	anim.play("fall")
	set_large_collider()

func go_to_duck_state():
	status = PlayerState.duck
	anim.play("duck")
	set_small_collider()

func exit_from_duck_state():
	set_large_collider()

func go_to_slide_state():
	status = PlayerState.slide
	anim.play("slide")
	set_small_collider()

func exit_from_slide_state():
	set_large_collider()

func go_to_dead_state():
	if status == PlayerState.dead:
		return

	status = PlayerState.dead
	anim.play("dead")
	velocity = Vector2.ZERO
	$CollisionShape2D.disabled = true

	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://scene/game_over.tscn")

# =========================
# Movimentação
# =========================

func move(delta):
	update_direction()

	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0

func update_direction():
	direction = Input.get_axis("left", "right")

	if direction < 0:
		anim.flip_h = true
	elif direction > 0:
		anim.flip_h = false

func can_jump() -> bool:
	return jump_count < max_jump_count

# =========================
# Collider
# =========================

func set_small_collider():
	collision_shape.shape.radius = 5
	collision_shape.shape.height = 10
	collision_shape.position.y = 3

func set_large_collider():
	collision_shape.shape.radius = 6
	collision_shape.shape.height = 16
	collision_shape.position.y = 0

# =========================
# Colisão com inimigos
# =========================

func _on_hitbox_area_entered(area: Area2D) -> void:
	# Verifica se quem colidiu foi um inimigo (Skeleton)
	var skeleton = area.get_parent()

	# Verifica se tem o método kill() e se NÃO está morto
	if skeleton.has_method("kill") and not skeleton.is_dead:
		# Se está caindo (velocity.y > 0), pisa no inimigo
		if velocity.y > 0:
			skeleton.kill()
			go_to_jump_state()  # Player faz um pulo extra após pisar
		else:
			# Se não está caindo, toma dano (colisão lateral)
			if skeleton.has_method("hurt"):
				skeleton.hurt()
			go_to_dead_state()
