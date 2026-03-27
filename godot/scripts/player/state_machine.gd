class_name StateMachine
extends Node
## Stack-based finite state machine for the player.
##
## Setup: Place as a child of CharacterBody2D.
##        Add State nodes as children of this node.
##        Call change_state("idle") from Player._ready() to boot.
##
## The machine auto-discovers all State children on _ready() and injects
## the parent CharacterBody2D as `state.player`.

var current_state: State
var states: Dictionary = {}  ## name (lowercase) -> State node

func _ready() -> void:
	var parent := get_parent() as CharacterBody2D
	for child: Node in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			(child as State).player = parent

func change_state(new_state_name: String) -> void:
	var new_state: State = states.get(new_state_name.to_lower())
	if new_state == null:
		push_error("StateMachine: state '%s' not found. Available: %s" % [
			new_state_name, str(states.keys())
		])
		return
	if current_state:
		current_state.exit()
	current_state = new_state
	current_state.enter()

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)
