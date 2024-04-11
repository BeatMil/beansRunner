extends CharacterBody3D


const SPEED = 10
const ACCERLERATE = 0.02
const DEACCERLERATE = 0.01
const DASH_MULTIPLIER = 3
const JUMP_VELOCITY = 32
const MOUSE_SENSITIVITY = 0.03


var is_dashing = false
var can_flash_jump = false
var is_flash_jump = false


var final_speed: float = SPEED


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$CanvasLayer/ProgressBar.value = 900
	print(deg_to_rad(-80))
	print(deg_to_rad(80))
	print(transform.basis)


func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENSITIVITY))
		$head.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENSITIVITY))
		$head.rotation.x = clampf($head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		# if $head.rotation.y != 0 or $head.rotation.z != 0:
		# 	$head.rotation.y = 0
		# 	$head.rotation.z = 0


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * 8 * delta
	elif is_on_floor():
		if $CrouchDashTimer.time_left > 0:
			is_flash_jump = true
		else:
			is_flash_jump = false

	# Handle Flash Jump.
	### Gotta check not flash jump first to prevent player from top speed
	if not is_flash_jump and not is_dashing:
		final_speed = lerpf(final_speed, SPEED, DEACCERLERATE)
	else:
		final_speed = lerpf(final_speed, SPEED*DASH_MULTIPLIER, ACCERLERATE)
	
	# Handel Dash
	if Input.is_action_just_pressed("dash"):
		$FlashJumpTimer.start()
	elif Input.is_action_just_released("dash"):
		can_flash_jump = false
	if Input.is_action_pressed("dash"):
		if $CanvasLayer/ProgressBar.value > 0:
			final_speed = lerpf(final_speed, SPEED*DASH_MULTIPLIER, ACCERLERATE)
		else:
			final_speed = SPEED
		is_dashing = true
	else:
		is_dashing = false

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

		if can_flash_jump == true:
			is_flash_jump = true
			$AnimationPlayer.play("flashjump")

	# Handle Crouch
	if Input.is_action_just_pressed("crouch"):
		$AcrobatPlayer.play("crouch")
		if can_flash_jump == true:
			is_flash_jump = true
			$AnimationPlayer.play("flashjump")
			$CrouchDashTimer.start()
	elif Input.is_action_just_released("crouch"):
		$AcrobatPlayer.play("uncrouch")

	# Godot Built-in XD
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * final_speed
		velocity.z = direction.z * final_speed
	else:
		pass
		velocity.x = move_toward(velocity.x, 0, 0.5)
		velocity.z = move_toward(velocity.z, 0, 0.5)




	float_up_and_down()
	move_and_slide()

	# others
	prevent_inifinite_fall()
	$CanvasLayer/VelocityLabel.text = "Velocity: %s" % velocity.length()
	$CanvasLayer/IsFlashjumpLabel.text = "is_flash_jump: %s" % [is_flash_jump]
	print($CrouchDashTimer.time_left)


func float_up_and_down():
	var float_dir = Input.get_axis("float_down", "float_up")
	if float_dir:
		velocity.y = float_dir * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, 0.1)


func prevent_inifinite_fall():
	if position.y < -10:
		position = $"../SpawnPoint".position
		$head.rotation = Vector3.ZERO


func _on_dash_refill_timer_timeout():
	if is_dashing:
		$CanvasLayer/ProgressBar.value -= 10
	else:
		$CanvasLayer/ProgressBar.value += 10


func _on_flash_jump_timer_timeout():
	can_flash_jump = true