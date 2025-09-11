extends CharacterBody3D

@export_category("Movement")
@export var playerSpeed:float
@export var terminalVelocity:float
@export var enableJump:bool
@export var jumpJets:bool
@export_range(0.0, 1000.0, 0.1, "or_greater") var jetForce:float
@export_range(0.0, 1000.0, 0.1, "or_greater") var jumpImpulse:float
@export_range(0, 10, 0.1) var movementHoverModifier:float #reduces speed of movement when hovering as a fractin of this number. Ex: 2 reduces by 1/2. 4 reduces by 1/4 etc.

var currentlyJumping:bool
var currentlyHovering:bool
var movementVelocity = Vector3.ZERO
var verticalVelocity = 0.0
var g = ProjectSettings.get_setting("physics/3d/default_gravity")



func _physics_process(delta):
	
#region Input Management
	###Input Handling
	var inputDirection = Input.get_vector("move_left", "move_right", "move_up", "move_down") #Vector tracking player input before applied top character, should work for both WASD and controller
	var lookDirection = Vector2.ZERO #TODO:Change to look at mouse for aiming, also controlled by right thumbstick on controller
	if Input.is_action_pressed("move_jump") && enableJump:
		if jumpJets:
			currentlyJumping = true
		elif is_on_floor() && not jumpJets:
			verticalVelocity = jumpImpulse
			currentlyJumping = true
	elif Input.is_action_just_released("move_jump") && currentlyJumping: 
		currentlyJumping = false
	
	if inputDirection != Vector2.ZERO:
		inputDirection = inputDirection.normalized()
	if lookDirection != Vector2.ZERO:
		lookDirection = lookDirection.normalized()
		$Pivot.basis = Basis.looking_at(lookDirection)
#endregion
	
#region Jump and Jumpjet Logic
	### Jump and/or Jumpjet Handling
	if jumpJets:
		if currentlyJumping: 
			verticalVelocity = clampf(movementVelocity.y + ((jetForce - g) * delta), -terminalVelocity, terminalVelocity) # Force of jump jets accounting for downward gravity pull
			currentlyHovering = true
		elif not is_on_floor() && not currentlyJumping: 
			verticalVelocity = clampf(movementVelocity.y - (g * delta), -terminalVelocity, terminalVelocity) # Gravity's pull when in the air
			currentlyHovering = true
		elif is_on_floor() && not currentlyJumping:
				verticalVelocity = 0.0
				currentlyHovering = false
	elif not is_on_floor(): #If not using Jump Jets and in the air
		verticalVelocity = clampf(movementVelocity.y - (g * delta), -terminalVelocity, terminalVelocity)
		currentlyHovering = true
	elif is_on_floor():
		currentlyHovering = false
#endregion
		
#region Movement and velocity logic
	if currentlyHovering:
		movementVelocity =  Vector3((inputDirection.x * playerSpeed) / movementHoverModifier, 
		verticalVelocity, 
		(inputDirection.y  * playerSpeed) / movementHoverModifier ) #Convert input vector into movement, as well as apply vertical movement to charcter
	else:
			movementVelocity =  Vector3(inputDirection.x * playerSpeed, 
			verticalVelocity, 
			inputDirection.y  * playerSpeed) #Convert input vector into movement, as well as apply vertical movement to charcter
	
	velocity = movementVelocity
#endregion
	
	
	
	move_and_slide()
		
	
	
	
