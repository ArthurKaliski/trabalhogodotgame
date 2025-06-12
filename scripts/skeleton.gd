extends CharacterBody2D

@export var speed: float = 30.0
@export var patrol_time: float = 2.0
var direction: int = -1
var is_dead = false

var can_invert: bool = true
var invert_cooldown: float = 0.2  # segundos de espera após inverter
var invert_cooldown_timer: float = 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	anim.play("walk")
	anim.flip_h = direction < 0  # começa virado pra esquerda


func _physics_process(delta):
	if is_dead:
		return
	
	# Atualiza cooldown para inverter direção
	if not can_invert:
		invert_cooldown_timer -= delta
		if invert_cooldown_timer <= 0:
			can_invert = true

	# Movimento horizontal
	velocity.x = direction * speed

	# Gravidade
	if not is_on_floor():
		velocity.y += 980 * delta
	else:
		velocity.y = 0
	
	# Move e checa colisões
	move_and_slide()

	# Verifica colisão lateral (Godot 4.x) e só inverte se cooldown permitir
	if can_invert:
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			if collision and abs(collision.get_normal().x) > 0.9:
				invert_direction()
				can_invert = false
				invert_cooldown_timer = invert_cooldown
				break

	# Garante animação andando
	if is_on_floor() and anim.animation != "walk":
		anim.play("walk")

func invert_direction():
	direction *= -1
	anim.flip_h = direction < 0  # inverter aqui para ajustar o lado correto
	anim.play("walk")
	
	# Empurra o personagem um pouco para fora da colisão na direção invertida
	position.x += direction * 2

func kill():
	if is_dead:
		return
	is_dead = true
	remove_from_group("enemies")
	anim.play("dead")
	collision_shape.disabled = true
	velocity = Vector2.ZERO
	await anim.animation_finished
	queue_free()

func hurt():
	if is_dead:
		return
	anim.play("hurt")
