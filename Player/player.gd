extends CharacterBody3D

@export_category("Movement")
#Editable Variables
@export var playerSpeed:float
@export var terminalVelocity:float
@export var enableJump:bool
@export var jumpJets:bool
@export_range(0.0, 1000.0, 0.1, "or_greater") var jetForce:float
@export_range(0.0, 1000.0, 0.1, "or_greater") var jumpImpulse:float
@export_range(0, 10, 0.1) var movementHoverModifier:float #reduces speed of movement when hovering as a fractin of this number. Ex: 2 reduces by 1/2. 4 reduces by 1/4 etc.
@export_range(0.0, 10.0, 0.25) var rotateSpeed:float
@export_range(0.0, 10.0, 0.25) var mechweight:float

@export_category("Player View")
@export var playerCam:Camera3D
@export var viewTracker:Node3D
@export var lookRayLength:float

@export_category("Player Model Nodes")
@export var playerRoot:Node3D
@export var playerBody:Node3D
@export var playerHead:Node3D



@export_category("Debug")
@export var debugEnable:bool
@export var debugSphere:PackedScene

#Calculated Variables
var currentlyJumping:bool
var currentlyHovering:bool
var movementDirection
var verticalVelocity = 0.0
var g = ProjectSettings.get_setting("physics/3d/default_gravity")



func _physics_process(delta):
	playerCam.look_at(playerHead.global_position)
	
#region Input Management
	###Input Handling
	var inputDirection = Input.get_vector("move_left", "move_right", "move_up", "move_down") #Vector tracking player input before applied top character, should work for both WASD and controller
	movementDirection = (playerRoot.transform.basis * Vector3(inputDirection.x, 0, inputDirection.y)).normalized()
	var lookDirection = Vector2.ZERO #TODO: add controller support for headlook direction
	
	if Input.is_action_pressed("move_jump") && enableJump:
		if jumpJets:
			currentlyJumping = true
		elif is_on_floor() && not jumpJets:
			verticalVelocity = jumpImpulse
			currentlyJumping = true
	elif Input.is_action_just_released("move_jump") && currentlyJumping: 
		currentlyJumping = false
	
	#if inputDirection != Vector2.ZERO:
	#	inputDirection = inputDirection.normalized()
	#if lookDirection != Vector2.ZERO:
	#	lookDirection = lookDirection.normalized()
	#	$Pivot.basis = Basis.looking_at(lookDirection)
		
	# Raycast from Camera to determine what direction mouse is looking relative to player character
	var spaceState = get_world_3d().direct_space_state
	var mousePosition = get_viewport().get_mouse_position()
	var lookRayOrigin = playerCam.project_ray_origin(mousePosition)
	var lookRayEnd = lookRayOrigin + playerCam.project_ray_normal(mousePosition) * lookRayLength
	var lookQuery = PhysicsRayQueryParameters3D.create(lookRayOrigin, lookRayEnd)
	lookQuery.collide_with_areas = true
	lookQuery.collide_with_bodies = true
	
	var lookResult = spaceState.intersect_ray(lookQuery)
	var lookPosition:Vector3
	if(!lookResult.is_empty()):
		playerHead.look_at(lookResult.position,Vector3.UP)
		lookPosition = lookResult.position
		DebugDraw3D.draw_ray($Body/Neck/Head.global_position,Vector3(lookPosition.x - playerHead.global_position.x , lookPosition.y - playerHead.global_position.y,lookPosition.z - playerHead.global_position.z), 500, Color.BLUE_VIOLET)
		
	
	
	if(debugEnable):
		print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
		print("mousePosition: ", mousePosition)
		print("lookRayOrigin: ", lookRayOrigin)
		print("lookRayEnd:    ", lookRayEnd)
		print("lookQuery:     ", lookQuery)
		print("lookResult:     ", lookResult)
		print("lookPosition:   ", lookResult.position)
		print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
		DebugDraw3D.draw_line(lookRayOrigin,lookRayEnd,Color.RED)
		#DebugDraw3D.draw_sphere(lookRayOrigin, 0.5, Color.BLACK)
		#DebugDraw3D.draw_ray(lookRayOrigin, playerCam.project_ray_normal(mousePosition), 500.0, Color.CYAN)
		DebugDraw3D.draw_ray(Vector3.ZERO, Vector3(0,1,0), 500, Color.YELLOW)
		#DebugDraw3D.draw_camera_frustum(playerCam, Color.BROWN)
		#DebugDraw3D.draw_position()
		if(lookResult.is_empty()):
			print("It's still empty you fucking moron")
		else:
			print("You're one iota less stupid")
	
		
		
#endregion
	
#region Jump and Jumpjet Logic
	### Jump and/or Jumpjet Handling
	if jumpJets:
		if currentlyJumping: 
			verticalVelocity = clampf(velocity.y + ((jetForce - g) * delta), -terminalVelocity, terminalVelocity) # Force of jump jets accounting for downward gravity pull
			currentlyHovering = true
		elif not is_on_floor() && not currentlyJumping: 
			verticalVelocity = clampf(velocity.y - (g * delta), -terminalVelocity, terminalVelocity) # Gravity's pull when in the air
			currentlyHovering = true
		elif is_on_floor() && not currentlyJumping:
				verticalVelocity = clampf(velocity.y - (g * delta), -terminalVelocity, terminalVelocity)
				currentlyHovering = false
	elif not is_on_floor(): #If not using Jump Jets and in the air
		verticalVelocity = clampf(velocity.y - (g * delta), -terminalVelocity, terminalVelocity)
		currentlyHovering = true
	elif is_on_floor():
		currentlyHovering = false
#endregion
		
#region Movement and velocity logic
	if currentlyHovering:
		velocity.x = lerp(velocity.x, (movementDirection.x * playerSpeed) / movementHoverModifier, delta * mechweight )
		velocity.z = lerp(velocity.z, (movementDirection.z * playerSpeed) / movementHoverModifier, delta * mechweight )
	else:
		velocity.x = lerp(velocity.x, (movementDirection.x * playerSpeed), delta * mechweight )
		velocity.z = lerp(velocity.z, (movementDirection.z * playerSpeed), delta * mechweight )
	velocity.y = verticalVelocity
	
	
	if(movementDirection != null && movementDirection!= Vector3.ZERO):
		var playerRotateTowards:Vector3
		var playerRotatex = lerp(velocity.x,movementDirection.x, delta * rotateSpeed)
		var playerRotatez = lerp(velocity.z,movementDirection.z, delta * rotateSpeed)
		playerRotateTowards = Vector3(playerRotatex, 0.0, playerRotatez)
		DebugDraw3D.draw_ray($Body.global_position, playerRotateTowards, 500, Color.BLUE)
		DebugDraw3D.draw_ray($Body.global_position, movementDirection, 500, Color.RED)
		playerBody.basis = Basis.looking_at(playerRotateTowards)
	
#endregion
	
	

	move_and_slide()
		
	
	
	
