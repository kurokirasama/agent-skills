use std assert
use ../utils.nu [create-test-dispatch handle-approval-decision guard-production-dispatch]

def main [] {
    print "Running tests for verification workflow and approval loop state machine..."
    test-create-test-dispatch
    test-approval-to-production
    test-rejection-and-revision-loop
    test-guard-production-dispatch
    print "All verification workflow tests completed successfully!"
}

def test-create-test-dispatch [] {
    print "  Test: create-test-dispatch forces recipient to user@example.com..."

    let input = {
        to: "student@work.example.edu"
        subject: "Revision de notas"
        body: "Sus notas han sido publicadas."
        from: "user@work.example.edu"
        signature: "Author Name"
    }

    let dispatch = (create-test-dispatch $input)

    assert ($dispatch.stage == "test")
    assert ($dispatch.recipient == "user@example.com")
    assert ($dispatch.subject == "[TEST] Revision de notas")
    assert ($dispatch.body | str contains "TEST EMAIL VERIFICATION")
    assert ($dispatch.body | str contains "student@work.example.edu")
    assert ($dispatch.original_target.to == "student@work.example.edu")

    print "  PASSED: create-test-dispatch"
}

def test-approval-to-production [] {
    print "  Test: handle-approval-decision on 'approve' produces clean production payloads..."

    let input = {
        to: "student@work.example.edu"
        subject: "Revision de notas"
        body: "Sus notas han sido publicadas."
        from: "user@work.example.edu"
        signature: "Author Name"
    }
    let dispatch = (create-test-dispatch $input)

    let decision_result = (handle-approval-decision $dispatch "approve")

    assert ($decision_result.status == "approved")
    assert ($decision_result.ready_for_production == true)
    assert (($decision_result.payloads | length) == 1)

    let prod = ($decision_result.payloads | first)
    assert ($prod.to == "student@work.example.edu")
    assert ($prod.subject == "Revision de notas")
    assert (not ($prod.subject | str starts-with "[TEST]"))
    assert (not ($prod.body | str contains "TEST EMAIL VERIFICATION"))
    assert ($prod.body | str contains "Sus notas han sido publicadas.")
    assert ($prod.body | str contains "Author Name")

    print "  PASSED: handle-approval-decision on approve"
}

def test-rejection-and-revision-loop [] {
    print "  Test: handle-approval-decision on 'reject' and 'revise'..."

    let input = {
        to: "director@work.example.edu"
        subject: "Presupuesto anual"
        body: "Borrador de presupuesto."
    }
    let dispatch = (create-test-dispatch $input)

    # Rejection without immediate revision
    let rejected = (handle-approval-decision $dispatch "reject")
    assert ($rejected.status == "rejected")
    assert ($rejected.ready_for_production == false)

    # Revision with updated body
    let revised = (handle-approval-decision $dispatch "revise" { body: "Presupuesto final ajustado." })
    assert ($revised.status == "revision_pending_test")
    assert ($revised.ready_for_production == false)
    assert ($revised.next_test_dispatch.recipient == "user@example.com")
    assert ($revised.next_test_dispatch.body | str contains "Presupuesto final ajustado.")

    print "  PASSED: rejection and revision loop"
}

def test-guard-production-dispatch [] {
    print "  Test: guard-production-dispatch blocks unapproved dispatches..."

    let unapproved = { ready_for_production: false, status: "pending" }
    let error_caught = (try {
        guard-production-dispatch $unapproved
        false
    } catch {
        true
    })
    assert ($error_caught == true)

    let approved = { ready_for_production: true, status: "approved" }
    let passed = (try {
        guard-production-dispatch $approved
        true
    } catch {
        false
    })
    assert ($passed == true)

    print "  PASSED: guard-production-dispatch"
}
