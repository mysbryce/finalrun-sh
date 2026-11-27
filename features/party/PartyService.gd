class_name PartyService
extends RefCounted
## Server-side party registry: create, invite/accept, leave, kick, pending
## invites and leader transfer.
##
## Network output is injected as callables so the party rules stay independent
## of the ServerManager node path.

const PartyScript = preload("res://features/party/Party.gd")

var _parties: Dictionary = {}
var _peer_party: Dictionary = {}
var _pending_invites: Dictionary = {}
## peer_id -> true for peers whose session party_invites preference is "nobody".
var _invites_blocked: Dictionary = {}
var _next_party_id: int = 1

var _notify: Callable = Callable()
var _send_client_rpc: Callable = Callable()
var _is_player_known: Callable = Callable()


func configure(
	notify: Callable,
	send_client_rpc: Callable,
	is_player_known: Callable
) -> void:
	_notify = notify
	_send_client_rpc = send_client_rpc
	_is_player_known = is_player_known


func get_party(peer_id: int) -> Party:
	var party_id: Variant = _peer_party.get(peer_id)
	if party_id == null:
		return null
	return _parties.get(int(party_id)) as Party


## RPC handler helper: create (or return the existing) party, tell the member
## and push the fresh state.
func handle_create(peer_id: int) -> void:
	var party := create_party(peer_id)
	if party == null:
		return
	_notify.call(peer_id, "Party created (leader)")
	send_party_state(party)


func create_party(peer_id: int) -> Party:
	var existing := get_party(peer_id)
	if existing != null:
		return existing
	var party := PartyScript.new(_next_party_id, peer_id) as Party
	_next_party_id += 1
	_parties[party.id] = party
	_peer_party[peer_id] = party.id
	return party


func invite_to_party(inviter_id: int, target_id: int, now_ms: int = Time.get_ticks_msec()) -> bool:
	if inviter_id <= 0 or target_id <= 0 or inviter_id == target_id:
		return false
	if not bool(_is_player_known.call(target_id)):
		return false
	if _invites_blocked.has(target_id):
		return false
	if get_party(target_id) != null:
		return false
	var party := get_party(inviter_id)
	if party == null:
		party = create_party(inviter_id)
	if party == null or party.is_full():
		return false
	_pending_invites[target_id] = {
		"inviter": inviter_id,
		"party_id": party.id,
		"expires_ms": now_ms + GameConst.PARTY_INVITE_TTL_MS,
	}
	_notify.call(target_id, "Party invite from player %d" % inviter_id)
	_send_client_rpc.call(
		target_id, "client_party_invite", [inviter_id, GameConst.PARTY_INVITE_TTL_MS / 1000]
	)
	_notify.call(inviter_id, "Invite sent to player %d" % target_id)
	return true


## Session invite permission for `peer_id`. Blocking also drops a pending
## invite addressed to that peer.
func set_invites_allowed(peer_id: int, allowed: bool) -> void:
	if allowed:
		_invites_blocked.erase(peer_id)
		return
	_invites_blocked[peer_id] = true
	_pending_invites.erase(peer_id)


func accept_party_invite(target_id: int, inviter_id: int, now_ms: int = Time.get_ticks_msec()) -> bool:
	var invite: Variant = _pending_invites.get(target_id)
	if invite == null:
		return false
	var invite_data: Dictionary = invite
	if int(invite_data.get("inviter", 0)) != inviter_id:
		return false
	_pending_invites.erase(target_id)
	if now_ms >= int(invite_data.get("expires_ms", 0)):
		_notify.call(target_id, "Party invite expired")
		return false
	if get_party(target_id) != null:
		return false
	var party := get_party(inviter_id)
	if party == null or party.is_full():
		return false
	if party.id != int(invite_data.get("party_id", -1)):
		return false
	if not party.add_member(target_id):
		return false
	_peer_party[target_id] = party.id
	_notify.call(target_id, "Joined the party")
	send_party_state(party)
	return true


func decline_party_invite(target_id: int, inviter_id: int) -> bool:
	var invite: Variant = _pending_invites.get(target_id)
	if not invite is Dictionary:
		return false
	if int((invite as Dictionary).get("inviter", 0)) != inviter_id:
		return false
	_pending_invites.erase(target_id)
	_notify.call(inviter_id, "Player %d declined the invite" % target_id)
	return true


func leave_party(peer_id: int) -> void:
	var party := get_party(peer_id)
	if party == null:
		return
	party.remove_member(peer_id)
	_peer_party.erase(peer_id)
	if party.is_empty():
		_parties.erase(party.id)
		return
	send_party_state(party)
	_notify.call(party.leader_id, "Party leader is now player %d" % party.leader_id)


func kick_from_party(leader_id: int, target_id: int) -> bool:
	var party := get_party(leader_id)
	if party == null or not party.is_leader(leader_id):
		return false
	if target_id == leader_id or not party.has_member(target_id):
		return false
	party.remove_member(target_id)
	_peer_party.erase(target_id)
	_notify.call(target_id, "You were kicked from the party")
	_send_client_rpc.call(target_id, "client_party_left", ["kicked"])
	send_party_state(party)
	return true


func send_party_state(party: Party) -> void:
	if party == null:
		return
	var info := {
		"active": true,
		"party_id": party.id,
		"leader_id": party.leader_id,
		"members": party.members.duplicate(),
	}
	for member: int in party.members:
		_notify.call(member, "Party: leader player %d, %d members" % [party.leader_id, party.members.size()])
		_send_client_rpc.call(member, "client_party_state", [info])


## Disconnect cleanup: drop the peer's own invite and any invite it sent, then
## remove it from its party.
func remove_peer(peer_id: int) -> void:
	_pending_invites.erase(peer_id)
	_invites_blocked.erase(peer_id)
	for target_value: Variant in _pending_invites.keys():
		var target_id: int = int(target_value)
		var invite: Variant = _pending_invites.get(target_id)
		if invite is Dictionary and int((invite as Dictionary).get("inviter", 0)) == peer_id:
			_pending_invites.erase(target_id)
	leave_party(peer_id)
