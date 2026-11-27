class_name NetUtil
extends RefCounted
## Static networking helpers shared by the server services.
##
## Every gameplay event targets instance members only. `rpc_to_members` is the
## low-level dispatch loop; it never broadcasts. `lib/` has no project imports,
## so the helpers take the calling Node instead of reading a singleton.

## Sender ids are peer ids; peer 1 is the server and never a request sender.
static func is_valid_sender(sender_id: int) -> bool:
	return sender_id > 0


static func is_peer_connected(node: Node, peer_id: int) -> bool:
	if peer_id <= 0 or not node.multiplayer.has_multiplayer_peer():
		return false
	return node.multiplayer.get_peers().has(peer_id)


## Sends an RPC to one connected peer. Returns false when no packet was sent.
## `args` is dispatched with a small arity switch because GDScript has no spread
## syntax for built-in RPC calls.
static func rpc_to_peer(
	node: Node,
	peer_id: int,
	callable_name: StringName,
	args: Array = []
) -> bool:
	if not is_peer_connected(node, peer_id):
		return false
	_dispatch_peer_rpc(node, peer_id, callable_name, args)
	return true


## Sends a client request to the server (peer 1). Callers still gate this with
## their own "client connected, not server" check.
static func rpc_to_server(node: Node, callable_name: StringName, args: Array = []) -> void:
	if not node.multiplayer.has_multiplayer_peer():
		return
	_dispatch_peer_rpc(node, 1, callable_name, args)


## Sends an RPC only to the given member peers of an instance.
##
## `only_peers` restricts the recipients; when empty every member is targeted.
## Peers that are not members or not connected are skipped.
static func rpc_to_members(
	node: Node,
	members: Array,
	callable_name: StringName,
	args: Array,
	only_peers: Array = []
) -> void:
	if not node.multiplayer.has_multiplayer_peer():
		return
	var connected: PackedInt32Array = node.multiplayer.get_peers()
	var targets: Array = only_peers if not only_peers.is_empty() else members
	for peer_value: Variant in targets:
		var peer: int = int(peer_value)
		if not members.has(peer):
			continue
		if not connected.has(peer):
			continue
		_dispatch_peer_rpc(node, peer, callable_name, args)


## Like rpc_to_members but never falls back to "everyone" for an empty peer list.
static func rpc_to_specific_members(
	node: Node,
	members: Array,
	callable_name: StringName,
	args: Array,
	peers: Array
) -> void:
	if peers.is_empty():
		return
	rpc_to_members(node, members, callable_name, args, peers)


## Grants synchronizer visibility to every member and revokes it from every
## other connected peer. Called on spawn, join, leave and transfer.
static func refresh_visibility(players: Array[Node], members: Array) -> void:
	if not _has_network(players):
		return
	var connected: PackedInt32Array = _multiplayer_for(players).get_peers()
	for player: Node in players:
		var sync := _synchronizer_for(player)
		if sync == null:
			continue
		for peer: int in connected:
			sync.set_visibility_for(peer, members.has(peer))


## Revokes visibility in both directions before a player is despawned: the
## leaving player's own synchronizer and every other player's view of them.
static func revoke_visibility(
	player: Node,
	members: Array,
	other_players: Array[Node],
	peer_id: int
) -> void:
	var sync := _synchronizer_for(player)
	if sync != null:
		for member: int in members:
			sync.set_visibility_for(member, false)
		sync.set_visibility_for(peer_id, false)
	for other: Node in other_players:
		if other == player:
			continue
		var other_sync := _synchronizer_for(other)
		if other_sync != null:
			other_sync.set_visibility_for(peer_id, false)


static func _dispatch_peer_rpc(
	node: Node,
	peer_id: int,
	callable_name: StringName,
	args: Array
) -> void:
	match args.size():
		0:
			node.rpc_id(peer_id, callable_name)
		1:
			node.rpc_id(peer_id, callable_name, args[0])
		2:
			node.rpc_id(peer_id, callable_name, args[0], args[1])
		3:
			node.rpc_id(peer_id, callable_name, args[0], args[1], args[2])
		4:
			node.rpc_id(peer_id, callable_name, args[0], args[1], args[2], args[3])
		_:
			push_error("NetUtil: unsupported argument count %d" % args.size())


static func _synchronizer_for(player: Node) -> MultiplayerSynchronizer:
	if player == null or not is_instance_valid(player):
		return null
	return player.get_node_or_null("MultiplayerSynchronizer") as MultiplayerSynchronizer


static func _multiplayer_for(players: Array[Node]) -> MultiplayerAPI:
	for player: Node in players:
		if player != null and is_instance_valid(player):
			return player.multiplayer
	return null


static func _has_network(players: Array[Node]) -> bool:
	var api := _multiplayer_for(players)
	return api != null and api.has_multiplayer_peer()
