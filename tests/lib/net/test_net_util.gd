extends TestCase
## Sender validation helpers are pure and need no live multiplayer peer.


func test_sender_validation() -> void:
	assert_true(NetUtil.is_valid_sender(1), "peer 1 is a valid sender id")
	assert_true(NetUtil.is_valid_sender(42), "positive peer ids are valid senders")
	assert_false(NetUtil.is_valid_sender(0), "peer 0 is not a valid sender")
	assert_false(NetUtil.is_valid_sender(-1), "negative peer ids are not valid senders")
