class_name State
extends Node
## Abstract base class for all player states.
## Add concrete state nodes as children of StateMachine.
## The `player` reference is injected by StateMachine._ready().

var player: CharacterBody2D

func enter() -> void:
	## Called when this state becomes the active state.
	pass

func exit() -> void:
	## Called just before this state is replaced by another.
	pass

func update(delta: float) -> void:
	## Called every physics frame while this state is active.
	## Responsible for movement, gravity, and self-initiated transitions.
	pass

func handle_input(event: InputEvent) -> void:
	## Called for every unhandled InputEvent while this state is active.
	## Use for discrete action transitions (jump pressed, dash pressed, etc.).
	pass
