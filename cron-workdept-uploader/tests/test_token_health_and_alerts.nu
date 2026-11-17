use std assert
use ../scripts/pipeline.nu [check-token-health send-token-alert]

def main [] {
    print "Running tests for token health monitoring and alerts..."
    test-check-token-health-valid
    test-check-token-health-invalid-simulator
    test-send-token-alert-dry-run
    print "All token health and alert tests passed successfully!"
}

def test-check-token-health-valid [] {
    print "  Test: check-token-health with current live or valid state..."
    let res = (check-token-health "workdept")
    assert ("valid" in $res)
    assert ("account" in $res)
    assert ($res.account == "workdept")
    print $"  PASSED: check-token-health returned valid=($res.valid)"
}

def test-check-token-health-invalid-simulator [] {
    print "  Test: check-token-health with non-existent account reports invalid..."
    let res = (check-token-health "non_existent_fake_account_12345")
    assert ($res.valid == false)
    assert ($res.message =~ "(?i)expired|missing|failed")
    print "  PASSED: check-token-health invalid simulator"
}

def test-send-token-alert-dry-run [] {
    print "  Test: send-token-alert in dry-run mode targets user@example.com..."
    let res = (send-token-alert --recipient "user@example.com" --dry-run)
    assert ($res.dry_run == true)
    assert ($res.discord_sent == true)
    assert ($res.email_sent == true)
    assert ($res.recipient == "user@example.com")
    print "  PASSED: send-token-alert dry-run"
}
