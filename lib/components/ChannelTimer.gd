class_name ChannelTimer
extends Node
## Generic server-side hold-interact channel.
##
## The owner adds this node under the actor's player, connects the signals, and
## starts it. Movement is checked by distance from the start position; every
## other rule is supplied by `cancel_check`, which returns "" to continue or one
## of the fixed reason strings to cancel. No feature or Node type is imported,
## so the component stays reusable by masks, revives, searches and future holds.

signal completed
signal cancelled(reason: String)

## Exact reason strings accepted by `cancel()` / `cancel_check()`.
const REASONS: Array[String] = [
	"moved",
	"out_of_range",
	"no_los",
	"damaged",
	"disconnected",
	"target_state",
	"actor_state",
	"left_instance",
	"invalid_state",
]

var _actor: Node3D = null
var _origin: Vector3 = Vector3.ZERO
var _max_move: float = 0.0
var _time_left: float = 0.0
var _cancel_check: Callable = Callable()
var _active: bool = false


func _ready() -> void:
	set_process(false)


func start(
	duration: float,
	actor: Node3D,
	max_move: float,
	cancel_check: Callable
) -> void:
	if _active:
		cancel("invalid_state")
	_actor = actor
	_max_move = maxf(max_move, 0.0)
	_time_left = maxf(duration, 0.0)
	_cancel_check = cancel_check
	_origin = actor.global_position if is_instance_valid(actor) else Vector3.ZERO
	_active = true
	set_process(true)


func is_active() -> bool:
	return _active


func time_left() -> float:
	return _time_left


func cancel(reason: String) -> void:
	if not _active:
		return
	var final_reason: String = reason
	if not REASONS.has(final_reason):
		push_error("ChannelTimer: invalid cancel reason '%s'" % reason)
		final_reason = "invalid_state"
	_active = false
	set_process(false)
	cancelled.emit(final_reason)


func _process(delta: float) -> void:
	if not _active:
		return
	if not is_instance_valid(_actor):
		cancel("actor_state")
		return
	if _max_move > 0.0 and _actor.global_position.distance_to(_origin) > _max_move:
		cancel("moved")
		return
	if _cancel_check.is_valid():
		var reason: String = String(_cancel_check.call())
		if reason != "":
			cancel(reason)
			return
	_time_left -= delta
	if _time_left <= 0.0:
		_finish()


func _finish() -> void:
	if not _active:
		return
	_active = false
	set_process(false)
	completed.emit()
