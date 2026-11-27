extends TestCase
## Permission matrix, payouts and party rules for the downed state.

const DownedScript = preload("res://features/downed/DownedService.gd")
const RoleControllerScript = preload("res://features/player/PlayerRoleController.gd")

const ALIVE: int = RoleControllerScript.LifeState.ALIVE
const DOWNED: int = RoleControllerScript.LifeState.DOWNED
const DEAD: int = RoleControllerScript.LifeState.DEAD
const CITIZEN: int = RoleControllerScript.Role.CITIZEN
const CRIMINAL: int = RoleControllerScript.Role.CRIMINAL
const COP: int = RoleControllerScript.Role.COP


func test_revive_matrix() -> void:
	assert_true(
		DownedScript.can_revive(CRIMINAL, ALIVE, CRIMINAL, DOWNED, true, false),
		"same party, same role, alive reviver revives"
	)
	assert_false(
		DownedScript.can_revive(CRIMINAL, ALIVE, CRIMINAL, DOWNED, false, false),
		"revive requires the same party"
	)
	assert_false(
		DownedScript.can_revive(CRIMINAL, ALIVE, COP, DOWNED, true, false),
		"revive requires the same role"
	)
	assert_false(
		DownedScript.can_revive(CRIMINAL, ALIVE, CRIMINAL, DOWNED, true, true),
		"only one reviver at a time"
	)
	assert_false(
		DownedScript.can_revive(CRIMINAL, DOWNED, CRIMINAL, DOWNED, true, false),
		"a downed actor cannot revive"
	)
	assert_false(
		DownedScript.can_revive(CRIMINAL, ALIVE, CRIMINAL, ALIVE, true, false),
		"an alive target is not revivable"
	)


func test_finish_matrix() -> void:
	assert_true(
		DownedScript.can_finish(true, ALIVE, DOWNED),
		"attack permission + live actor + downed target finishes"
	)
	assert_false(DownedScript.can_finish(false, ALIVE, DOWNED), "attack permission is required")
	assert_false(DownedScript.can_finish(true, DOWNED, DOWNED), "a downed actor cannot finish")
	assert_false(DownedScript.can_finish(true, ALIVE, ALIVE), "an alive target is not finished")
	assert_false(DownedScript.can_finish(true, ALIVE, DEAD), "a dead target is not finished")


func test_cuff_matrix() -> void:
	assert_true(DownedScript.can_cuff(COP, ALIVE, CRIMINAL, DOWNED), "COP cuffs a downed CRIMINAL")
	assert_false(DownedScript.can_cuff(COP, ALIVE, COP, DOWNED), "COP cannot cuff a COP")
	assert_false(DownedScript.can_cuff(CRIMINAL, ALIVE, CRIMINAL, DOWNED), "only a COP may cuff")
	assert_false(DownedScript.can_cuff(COP, DOWNED, CRIMINAL, DOWNED), "a downed COP cannot cuff")
	assert_false(DownedScript.can_cuff(COP, ALIVE, CRIMINAL, ALIVE), "the target must be downed")


func test_search_matrix() -> void:
	assert_true(DownedScript.can_search(CRIMINAL, ALIVE, CRIMINAL, DOWNED), "criminal searches a body")
	assert_true(DownedScript.can_search(CRIMINAL, ALIVE, COP, DOWNED), "criminal searches a downed cop")
	assert_true(DownedScript.can_search(COP, ALIVE, CRIMINAL, DOWNED), "cop searches a criminal")
	assert_false(DownedScript.can_search(COP, ALIVE, COP, DOWNED), "cop cannot search a cop")
	assert_false(DownedScript.can_search(CITIZEN, ALIVE, CRIMINAL, DOWNED), "citizens never search")
	assert_false(DownedScript.can_search(CRIMINAL, DOWNED, CRIMINAL, DOWNED), "downed cannot search")
	assert_false(DownedScript.can_search(CRIMINAL, ALIVE, CRIMINAL, ALIVE), "only downed bodies")


func test_seizure_payouts() -> void:
	var bag: Dictionary = ItemUtils.make_item(1, "diamond", 1000)
	assert_eq(DownedScript.seizure_reward(bag, "bag"), 250, "seizure pays 25% of bag value")
	var gear: Dictionary = ItemUtils.make_item(2, "rifle", 2200)
	assert_eq(DownedScript.seizure_reward(gear, "gear"), 0, "seized gear pays nothing")
	var odd: Dictionary = ItemUtils.make_item(3, "cash", 999)
	assert_eq(DownedScript.seizure_reward(odd, "bag"), 249, "seizure rounds down")


func test_payout_order() -> void:
	# cuff (50% of bag) > seizure (25% of bag) > finish (0).
	var bag_value: int = 1000
	var cuff: Dictionary = RoleControllerScript.surrender_outcome(CRIMINAL, COP, bag_value)
	var seizure: int = DownedScript.seizure_reward(ItemUtils.make_item(1, "x", bag_value), "bag")
	assert_eq(int(cuff.get("reward", 0)), 500, "cuff pays half the bag")
	assert_eq(seizure, 250, "seizure pays a quarter of the bag")
	assert_true(int(cuff["reward"]) > seizure, "cuff beats seizure")
	assert_true(seizure > 0, "seizure beats finishing for zero")


func test_party_role_conflict() -> void:
	assert_true(
		PlayerService.party_role_conflict([CITIZEN, COP], CRIMINAL),
		"mask is rejected when a party member is COP"
	)
	assert_true(
		PlayerService.party_role_conflict([CITIZEN, CRIMINAL], COP),
		"cop duty is rejected when a party member is CRIMINAL"
	)
	assert_false(
		PlayerService.party_role_conflict([CITIZEN, CRIMINAL], CRIMINAL),
		"criminals may party with citizens"
	)
	assert_false(
		PlayerService.party_role_conflict([CITIZEN, COP], COP),
		"cops may party with citizens"
	)


func test_party_friendly_fire_is_off() -> void:
	assert_true(
		RoleControllerScript.can_attack_roles(CRIMINAL, CRIMINAL, "LootyBay", false),
		"default keeps existing attack behavior"
	)
	assert_false(
		RoleControllerScript.can_attack_roles(CRIMINAL, CRIMINAL, "LootyBay", false, true),
		"same party blocks attacks (and finish-off)"
	)
	assert_false(
		RoleControllerScript.can_attack_roles(COP, CRIMINAL, "LootyBay", false, true),
		"same party blocks cop attacks too"
	)
