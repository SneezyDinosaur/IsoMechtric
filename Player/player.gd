extends CharacterBody3D

@export_category("Movement")
@export var playerSpeed:float
@export var terminalVelocity:float

var movementVelocity = Vector3.ZERO
var verticalVelocity = 0.0
var g = ProjectSettings.get_setting("physics/3d/default_gravity")



func _physics_process(delta):
	
	var inputDirection = Input.get_vector("move_left", "move_right", "move_up", "move_down") #Vector tracking player input before applied top character, should work for both WASD and controller
	var lookDirection = Vector2.ZERO #TODO:Change to look at mouse for aiming, also controlled by right thumbstick on controller
	
	if inputDirection != Vector2.ZERO:
		inputDirection = inputDirection.normalized()
	if lookDirection != Vector2.ZERO:
		lookDirection = lookDirection.normalized()
		$Pivot.basis = Basis.looking_at(lookDirection)
	
	print("Input:", inputDirection)
	
	if not is_on_floor(): 
		verticalVelocity = clampf(movementVelocity.y - (g * delta), -terminalVelocity, terminalVelocity)
		
	movementVelocity =  Vector3(inputDirection.x * playerSpeed, 
	verticalVelocity, 
	inputDirection.y  * playerSpeed) #Convert input vector into movement, as well as apply vertical movement to charcter
	
	print("Movement:", movementVelocity)
	velocity = movementVelocity
	move_and_slide()
		
	
	
	
