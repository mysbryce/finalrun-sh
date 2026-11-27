extends TestCase

const DWELL := GameConst.BOOT_TITLE_DWELL_MS
const SKIP_AFTER := GameConst.BOOT_SKIP_AFTER_MS
const CEF_TIMEOUT := GameConst.BOOT_CEF_TIMEOUT_MS
const CONNECT_TIMEOUT := GameConst.BOOT_CONNECT_TIMEOUT_MS


func _started() -> BootFlow:
	var boot := BootFlow.new()
	boot.start(0, "0.1.0")
	return boot


## A flow already in `connecting` (page ready, dwell over).
func _connecting() -> BootFlow:
	var boot := _started()
	boot.on_page_ready(10)
	boot.tick(DWELL)
	return boot


func test_skip_threshold() -> void:
	var boot := _started()
	var early := boot.skip(SKIP_AFTER - 1)
	var late := boot.skip(SKIP_AFTER)
	var again := boot.skip(SKIP_AFTER + 1)
	assert_false(early, "skip refused before 250 ms")
	assert_true(late, "skip accepted after 250 ms")
	assert_false(again, "second skip has no effect")
	assert_true(boot.title_done, "skip ends the dwell")


func test_connect_after_dwell_then_page() -> void:
	var boot := _started()
	var at_dwell := boot.tick(DWELL)
	var phase_waiting := boot.phase
	boot.on_page_ready(DWELL + 10)
	var after_ready := boot.tick(DWELL + 20)
	assert_eq(at_dwell, "", "no connect before page ready")
	assert_eq(phase_waiting, "cef", "dwell done, page pending -> cef")
	assert_eq(after_ready, "connect", "connect once both gates pass")
	assert_eq(boot.phase, "connecting", "phase connecting")


func test_connect_after_page_then_dwell() -> void:
	var boot := _started()
	boot.on_page_ready(100)
	var before_dwell := boot.tick(DWELL - 1)
	var phase_title := boot.phase
	var at_dwell := boot.tick(DWELL)
	assert_eq(before_dwell, "", "no connect before dwell")
	assert_eq(phase_title, "title", "still title")
	assert_eq(at_dwell, "connect", "connect at dwell end")


func test_skip_lets_connect_early() -> void:
	var boot := _started()
	boot.on_page_ready(100)
	boot.skip(SKIP_AFTER)
	assert_eq(boot.tick(SKIP_AFTER + 1), "connect", "skip + page ready connects before dwell")


func test_cef_timeout() -> void:
	var boot := _started()
	boot.tick(DWELL)
	var before := boot.tick(CEF_TIMEOUT - 1)
	var at := boot.tick(CEF_TIMEOUT)
	assert_eq(before, "", "no failure before timeout")
	assert_eq(at, "fail_cef", "fail_cef at timeout")
	assert_eq(boot.phase, "failed", "phase failed")
	assert_eq(boot.error, "cef_timeout", "error cef_timeout")


func test_late_page_after_cef_timeout() -> void:
	var boot := _started()
	boot.tick(CEF_TIMEOUT)
	boot.on_page_ready(CEF_TIMEOUT + 100)
	var phase_after := boot.phase
	var error_after: Variant = boot.error
	var action := boot.tick(CEF_TIMEOUT + 200)
	assert_eq(phase_after, "cef", "late page returns to cef")
	assert_eq(error_after, null, "error cleared")
	assert_eq(action, "connect", "next tick connects")


func test_cef_retry_waits_for_page() -> void:
	var boot := _started()
	boot.tick(CEF_TIMEOUT)
	var action := boot.retry(CEF_TIMEOUT + 10)
	var phase_after := boot.phase
	var no_connect := boot.tick(CEF_TIMEOUT + 20)
	var no_fail := boot.tick(CEF_TIMEOUT + 10 + CEF_TIMEOUT - 1)
	boot.on_page_ready(CEF_TIMEOUT + 30)
	var reconnect := boot.tick(CEF_TIMEOUT + 40)
	assert_eq(action, "reload", "cef retry reloads")
	assert_eq(phase_after, "cef", "retry -> cef")
	assert_eq(no_connect, "", "no connect before ready")
	assert_eq(no_fail, "", "cef timer restarted on retry")
	assert_eq(reconnect, "connect", "connect after ready again")


func test_connect_timeout() -> void:
	var boot := _connecting()
	var before := boot.tick(DWELL + CONNECT_TIMEOUT - 1)
	var at := boot.tick(DWELL + CONNECT_TIMEOUT)
	assert_eq(before, "", "no abort before timeout")
	assert_eq(at, "abort_connect", "abort at timeout")
	assert_eq(boot.phase, "failed", "phase failed")
	assert_eq(boot.error, "connection_timeout", "error connection_timeout")


func test_retry_after_connection_failed() -> void:
	var boot := _connecting()
	boot.on_connection_failed("connection_failed")
	var failed_phase := boot.phase
	var action := boot.retry(DWELL + 100)
	assert_eq(failed_phase, "failed", "connection failure fails")
	assert_eq(action, "connect", "retry reconnects")
	assert_eq(boot.phase, "connecting", "phase connecting")
	assert_eq(boot.error, null, "error cleared")
	assert_eq(boot.tick(DWELL + 100 + CONNECT_TIMEOUT - 1), "", "connect timer restarted")


func test_connection_failed_ignored_unless_connecting() -> void:
	var boot := _started()
	boot.on_connection_failed("connection_failed")
	assert_eq(boot.phase, "title", "ignored in title")
	assert_eq(boot.retry(10), "", "retry outside failed does nothing")


func test_retry_after_cef_timeout_reloads() -> void:
	var boot := _started()
	boot.tick(CEF_TIMEOUT)
	assert_eq(boot.retry(CEF_TIMEOUT + 1), "reload", "cef_timeout retry reloads")
	assert_false(boot.page_ready, "page ready reset")


func test_view_keys() -> void:
	var boot := _started()
	boot.tick(SKIP_AFTER)
	var view := boot.view()
	var keys := view.keys()
	keys.sort()
	assert_eq(keys, ["buildId", "canRetry", "canSkipTitle", "error", "phase", "progress"], "six BootView keys")
	assert_eq(view["buildId"], "0.1.0", "build id")
	assert_eq(view["progress"], null, "no progress")
	assert_true(view["canSkipTitle"], "skip allowed in the window")
	assert_false(view["canRetry"], "no retry while booting")
	boot.tick(CEF_TIMEOUT)
	var failed := boot.view()
	assert_true(failed["canRetry"], "retry when failed")
	assert_false(failed["canSkipTitle"], "no skip when failed")
	assert_eq(failed["error"], "cef_timeout", "error in view")


func test_parse_endpoint() -> void:
	var fallback := BootFlow.parse_endpoint(PackedStringArray())
	assert_eq(fallback,{"host": "127.0.0.1", "port": GameConst.PORT, "ok": true}, "default endpoint")
	assert_eq(
		BootFlow.parse_endpoint(PackedStringArray(["--connect", "10.0.0.2:7000"])),
		{"host": "10.0.0.2", "port": 7000, "ok": true},
		"--connect host:port"
	)
	assert_eq(
		BootFlow.parse_endpoint(PackedStringArray(["--connect=host:80"])),
		{"host": "host", "port": 80, "ok": true},
		"--connect=host:port"
	)
	assert_false(BootFlow.parse_endpoint(PackedStringArray(["--connect", "a:0"]))["ok"], "port 0 is bad")
	assert_false(BootFlow.parse_endpoint(PackedStringArray(["--connect"]))["ok"], "--connect last is bad")
	assert_false(BootFlow.parse_endpoint(PackedStringArray(["--connect", "--ui-dev"]))["ok"], "--connect then flag is bad")
	assert_false(BootFlow.parse_endpoint(PackedStringArray(["--connect", "nocolon"]))["ok"], "no colon is bad")
	assert_eq(
		BootFlow.parse_endpoint(PackedStringArray(["--connect=:7000"])),
		{"host": "127.0.0.1", "port": GameConst.PORT, "ok": false},
		"empty host is bad, defaults returned"
	)
