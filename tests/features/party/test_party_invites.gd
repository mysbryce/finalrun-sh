extends TestCase
## Party invite lifecycle: expiry (TTL) and decline.

const INVITER: int = 100
const TARGET: int = 101
const OTHER: int = 102
const NOW_MS: int = 1000

var _notes: Array = []


func _make_service() -> PartyService:
	_notes = []
	var service := PartyService.new()
	service.configure(
		func(peer_id: int, text: String) -> void: _notes.append([peer_id, text]),
		func(_peer_id: int, _method: StringName, _args: Array = []) -> void: pass,
		func(_peer_id: int) -> bool: return true
	)
	return service


func test_accept_within_ttl_joins() -> void:
	var service := _make_service()
	assert_true(service.invite_to_party(INVITER, TARGET, NOW_MS), "invite sent")
	var ok := service.accept_party_invite(TARGET, INVITER, NOW_MS + GameConst.PARTY_INVITE_TTL_MS - 1)
	assert_true(ok, "accept within the TTL works")
	assert_true(service.get_party(TARGET) != null, "target joined the party")


func test_accept_after_ttl_fails_and_erases() -> void:
	var service := _make_service()
	service.invite_to_party(INVITER, TARGET, NOW_MS)
	var late_ms := NOW_MS + GameConst.PARTY_INVITE_TTL_MS
	assert_false(service.accept_party_invite(TARGET, INVITER, late_ms), "late accept fails")
	assert_true(_notes.has([TARGET, "Party invite expired"]), "target is told the invite expired")
	assert_true(service.get_party(TARGET) == null, "target did not join")
	assert_false(service.accept_party_invite(TARGET, INVITER, NOW_MS), "expired invite was erased")


func test_decline_only_for_matching_inviter() -> void:
	var service := _make_service()
	service.invite_to_party(INVITER, TARGET, NOW_MS)
	assert_false(service.decline_party_invite(TARGET, OTHER), "decline with the wrong inviter fails")
	assert_true(service.decline_party_invite(TARGET, INVITER), "decline with the matching inviter works")
	assert_true(_notes.has([INVITER, "Player %d declined the invite" % TARGET]), "inviter is told")
	assert_false(service.decline_party_invite(TARGET, INVITER), "second decline finds no invite")


func test_declined_invite_cannot_be_accepted() -> void:
	var service := _make_service()
	service.invite_to_party(INVITER, TARGET, NOW_MS)
	service.decline_party_invite(TARGET, INVITER)
	assert_false(service.accept_party_invite(TARGET, INVITER, NOW_MS), "declined invite cannot be accepted")
	assert_true(service.get_party(TARGET) == null, "target is not in a party")
