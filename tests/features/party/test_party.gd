extends TestCase
## Party data rules: max 3, leader transfer, membership checks.

const PartyScript = preload("res://features/party/Party.gd")


func test_party_membership_and_leader() -> void:
	var party = PartyScript.new(1, 100)
	assert_eq(party.size(), 1, "party starts with the leader")
	assert_true(party.is_leader(100), "creator is the leader")
	assert_true(party.add_member(101), "party accepts second member")
	assert_true(party.add_member(102), "party accepts third member")
	assert_eq(party.size(), 3, "party reaches max size 3")
	assert_true(party.is_full(), "party reports full at 3")
	assert_true(not party.add_member(103), "party rejects fourth member")
	assert_eq(party.size(), 3, "party stays at max size 3")
	assert_true(not PartyScript.new(2, 200).add_member(200), "duplicate member is rejected")

	assert_true(party.remove_member(100), "leader can leave")
	assert_eq(party.leader_id, 101, "leadership transfers to the first remaining member")
	assert_eq(party.size(), 2, "party shrinks after leave")
	assert_true(not party.remove_member(999), "removing a non-member fails")


func test_party_max_members_comes_from_game_const() -> void:
	assert_eq(PartyScript.MAX_MEMBERS, GameConst.PARTY_MAX_MEMBERS, "party max is the shared constant")
