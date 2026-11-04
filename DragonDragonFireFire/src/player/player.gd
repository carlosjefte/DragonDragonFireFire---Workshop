class_name Player
extends CharacterBody2D

enum State
{
	UNDEFINED,
	MOVE,
	DEAD,
}

const _FIRE_BALL_SCENE : PackedScene = preload("res://projectiles/fire_ball.tscn")
const _FIRE_BALL_OFFSET_LEFT : Vector2 = Vector2(-8.0, -8.0)
const _FIRE_BALL_OFFSET_RIGHT : Vector2 = Vector2(8.0, -8.0)
const _FIRE_BALL_OFFSET_UP_LEFT : Vector2 = Vector2(-3.0, -16.0)
const _FIRE_BALL_OFFSET_UP_RIGHT : Vector2 = Vector2(3.0, -16.0)
const _FIRE_BALL_CADENCE : float = (1.0 / 5.5) # 5.5 per second

const _SPEED = 80.0
const _JUMP_VELOCITY = -166.0
const _MAX_FALL_SPEED = 130.0

const _JUMP_BUFFER_TIME : float = 0.1
const _FIRE_BALL_BUFFER_TIME : float = 0.1
const _COYOTE_TIME : float = 0.075

const _INVINCIBILITY_TIME : float = 2.0
const _INVINCIBILITY_FLASH_SPEED : float = 20.0

const _FIRE_SPIT_ANIMATION_TIME : float = 0.15

var _cur_state : State = State.MOVE
var _cur_dir : Types.Direction = Types.Direction.RIGHT
var _touched_by_enemy : bool = false

var _has_invincibility_frames : bool = false
var _invincibility_frames : float = 0.0

var _jump_buffer_timer : float = _JUMP_BUFFER_TIME + 0.01 
var _fire_ball_buffer_timer : float = _FIRE_BALL_BUFFER_TIME + 0.01 

var _time_since_last_ground_contact : float = 0.0
var _time_since_last_fire_spit : float = _FIRE_SPIT_ANIMATION_TIME + 0.01 

var _looking_up : bool = false

# DICA: Declare as variáveis de entrada da IA (`ai_input_direction`, `ai_input_jump`, 
# `ai_input_fire`, `ai_input_up`, `ai_input_down`) que serão preenchidas pelo `PlayerAIController`.
var ai_input_direction: float = 0.0
var ai_input_jump: bool = false
var ai_input_fire: bool = false
var ai_input_up: bool = false
var ai_input_down: bool = false

@onready var _visuals : Node2D = $Visuals
@onready var _sprite_head : AnimatedSprite2D = $Visuals/AnimatedSprite2DHead
@onready var _sprite_body : AnimatedSprite2D = $Visuals/AnimatedSprite2DBody
@onready var _head_check_component : HeadCheckComponent = $HeadCheckComponent
@onready var _stuck_inside_geometry_component : StuckInsideGeometryComponent = $StuckInsideGeometryComponent
@onready var _one_way_platform_detector : ShapeCast2D = %OneWayPlatformDetector

@onready var initial_position : Vector2 = global_position


func _ready() -> void:
	_sprite_head.play("normal")
	_sprite_body.play("idle")


func _process(delta : float) -> void:
	_handle_buffered_inputs(delta)


func _handle_buffered_inputs(delta : float) -> void:
	# DICA: Gerencie os buffers de entrada permitindo tanto o teclado quanto o agente de RL.
	# 1. Incremente os timers de buffer com `delta`.
	# 2. Verifique se a ação de pulo foi acionada por `Input.is_action_just_pressed("jump")` 
	#    OU pela variável da IA (`ai_input_jump`). Se sim, zere o `_jump_buffer_timer`.
	# 3. Faça o mesmo para o tiro (`Input.is_action_just_pressed("fire")` ou `ai_input_fire`),
	#    zerando o `_fire_ball_buffer_timer`.
	pass


func _physics_process(delta : float) -> void:
	if GameState.is_halted():
		_update_animation()
		return

	if _has_invincibility_frames:
		_invincibility_frames -= delta
		if _invincibility_frames <= 0.0:
			_has_invincibility_frames = false
	
	_time_since_last_fire_spit += delta

	_update_invincibility_visuals()
	
	match _cur_state:
		State.MOVE:
			_physics_process_move(delta)
		State.DEAD:
			_physics_process_dead(delta)
		_:
			pass
	
	_update_animation()
	
	Teleport.handle_teleport(self)

	if _head_check_component.is_hit():
		_handle_death()
	if _stuck_inside_geometry_component.has_been_stuck():
		_handle_death()


func _physics_process_move(delta : float) -> void:
	if _touched_by_enemy and not Debug.player_invincible:
		_handle_death()
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_on_floor():
		_time_since_last_ground_contact = 0.0
	else:
		_time_since_last_ground_contact += delta

	# DICA: Verifique se o comando para olhar/apontar para baixo foi pressionado 
	# via teclado ("down") ou pela IA (`ai_input_down`).
	var down_pressed : bool = false # Substitua por sua lógica aqui
	_one_way_platform_detector.force_shapecast_update()

	var jump_buffered : bool = _jump_buffer_timer <= _JUMP_BUFFER_TIME
	if jump_buffered and _time_since_last_ground_contact <= _COYOTE_TIME:
		_jump_buffer_timer = _JUMP_BUFFER_TIME + 0.01 
		if down_pressed and _one_way_platform_detector.is_colliding():
			SoundPool.play_sound(SoundPool.SOUND_PLAYER_DROP_PLATFORM)
			position.y += 2.0
		else:
			velocity.y = _JUMP_VELOCITY
			_time_since_last_ground_contact = _COYOTE_TIME + 0.01 
			SoundPool.play_sound(SoundPool.SOUND_PLAYER_JUMP)

	var fire_ball_shot_buffered : bool = _fire_ball_buffer_timer <= _FIRE_BALL_BUFFER_TIME
	if fire_ball_shot_buffered and _time_since_last_fire_spit >= _FIRE_BALL_CADENCE:
		_fire_ball_buffer_timer = _FIRE_BALL_BUFFER_TIME + 0.01 
		_shoot_fire_ball()
	
	# DICA: Integre o comando de olhar para cima da IA (`ai_input_up`) junto com o input de teclado ("up").
	_looking_up = false # Substitua por sua lógica aqui

	_handle_direction_actions()
	
	if velocity.y > _MAX_FALL_SPEED:
		velocity.y = _MAX_FALL_SPEED
	move_and_slide()


func _physics_process_dead(_delta : float) -> void:
	pass


func grant_invincibility() -> void:
	_has_invincibility_frames = true
	_invincibility_frames = _INVINCIBILITY_TIME


func _update_invincibility_visuals() -> void:
	if _has_invincibility_frames:
		_visuals.modulate.a = 1.0 if int(_invincibility_frames * _INVINCIBILITY_FLASH_SPEED) % 2 == 0 else 0.5
	else:
		_visuals.modulate.a = 1.0


func _handle_direction_actions() -> void:
	# DICA: Defina a direção do movimento horizontal combinando a IA e o teclado.
	# 1. Comece pegando o valor de `ai_input_direction`.
	# 2. Se `ai_input_direction` for zero, faça o fallback para o teclado usando `Input.get_axis("left", "right")`.
	# 3. Atualize a velocidade `velocity.x` e a direção visual `_cur_dir` com base nesse valor final.
	var direction : float = 0.0 # Implemente a lógica aqui
	
	if direction:
		velocity.x = direction * _SPEED
		if direction < 0:
			_cur_dir = Types.Direction.LEFT
		else:
			_cur_dir = Types.Direction.RIGHT
	else:
		velocity.x = move_toward(velocity.x, 0, _SPEED)


func _shoot_fire_ball() -> void:
	var fire_ball : FireBall = _FIRE_BALL_SCENE.instantiate()
	get_parent().add_child(fire_ball)

	if _looking_up:
		fire_ball.set_up()
		if _cur_dir == Types.Direction.LEFT:
			fire_ball.global_position = global_position + _FIRE_BALL_OFFSET_UP_LEFT
		else:
			fire_ball.global_position = global_position + _FIRE_BALL_OFFSET_UP_RIGHT
	else:
		if _cur_dir == Types.Direction.LEFT:
			fire_ball.set_left()
			fire_ball.global_position = global_position + _FIRE_BALL_OFFSET_LEFT
		else:
			fire_ball.set_right()
			fire_ball.global_position = global_position + _FIRE_BALL_OFFSET_RIGHT

	_time_since_last_fire_spit = 0.0
	SoundPool.play_sound(SoundPool.SOUND_FIRE_SHOT)


func _handle_death() -> void:
	Signals.player_died.emit()
	_cur_state = State.DEAD

	var sync_node = get_tree().current_scene.find_child("Sync", true, false)
	var is_training_mode = false
	
	if sync_node and "control_mode" in sync_node:
		if sync_node.control_mode == 1: 
			is_training_mode = true

	# DICA: Gerencie o comportamento de morte de acordo com o modo de jogo.
	# Se estiver em `is_training_mode`, a IA não deve reiniciar a cena inteira, 
	# mas sim resetar a posição do player (`global_position = initial_position`), 
	# zerar a velocidade e voltar o estado para `State.MOVE`.
	# Caso contrário, execute o comportamento padrão de morte do jogo.
	pass


func _update_animation() -> void:
	if GameState.is_halted():
		_sprite_head.pause()
		_sprite_body.pause()
		return
	
	_visuals.scale.x = 1.0 if _cur_dir == Types.Direction.RIGHT else -1.0

	match _cur_state:
		State.UNDEFINED:
			assert(false)
			_sprite_body.play("idle")
		State.MOVE:
			if not is_on_floor():
				if velocity.y < 0.0:
					_sprite_body.play("jump_up")
				else:
					_sprite_body.play("jump_down")
			elif abs(velocity.x) > 0.1:
				_sprite_body.play("walk")
			else:
				_sprite_body.play("idle")

		State.DEAD:
			_sprite_body.play("hurt")

	if _cur_state == State.MOVE:
		if _time_since_last_fire_spit < _FIRE_SPIT_ANIMATION_TIME:
			if _looking_up:
				if not is_on_floor() and velocity.y < 0.0:
					_sprite_head.play("jump_fire_up")
				else:
					_sprite_head.play("fire_up")
			else:
				if not is_on_floor() and velocity.y < 0.0:
					_sprite_head.play("jump_fire")
				else:
					_sprite_head.play("fire")
		else:
			if _looking_up:
				if not is_on_floor() and velocity.y < 0.0:
					_sprite_head.play("jump_up")
				else:
					_sprite_head.play("normal_up")
			else:
				if not is_on_floor() and velocity.y < 0.0:
					_sprite_head.play("jump")
				else:
					_sprite_head.play("normal")
	else:
		_sprite_head.play("invisible")


func _on_enemy_detection_hitbox_body_entered(_body):
	if _has_invincibility_frames:
		return
	_touched_by_enemy = true
