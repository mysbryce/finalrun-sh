class_name Party
extends RefCounted
## A small server-side party. Parties are pure data so they can be unit tested
## without a SceneTree or a live network connection.

const MAX_MEMBERS: int = 3

var id: int = 0
var leader_id: int = 0
var members: Array[int] = []


func _init(p_id: int = 0, p_leader_id: int = 0) -> void:
	id = p_id
	if p_leader_id > 0:
		leader_id = p_leader_id
		members.append(p_leader_id)


func size() -> int:
	return members.size()


func is_empty() -> bool:
	return members.is_empty()


func is_full() -> bool:
	return members.size() >= MAX_MEMBERS


func has_member(peer_id: int) -> bool:
	return members.has(peer_id)


func is_leader(peer_id: int) -> bool:
	return leader_id == peer_id


## Adds a member. Returns false when the party is already at MAX_MEMBERS or the
## peer is already present.
func add_member(peer_id: int) -> bool:
	if peer_id <= 0 or members.has(peer_id) or is_full():
		return false
	members.append(peer_id)
	if leader_id == 0:
		leader_id = peer_id
	return true


## Removes a member and transfers leadership to the first remaining member when
## the leader leaves.
func remove_member(peer_id: int) -> bool:
	if not members.has(peer_id):
		return false
	members.erase(peer_id)
	if leader_id == peer_id:
		leader_id = members[0] if not members.is_empty() else 0
	return true


func set_leader(peer_id: int) -> bool:
	if not members.has(peer_id):
		return false
	leader_id = peer_id
	return true
