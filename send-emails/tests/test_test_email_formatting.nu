use std assert
use ../utils.nu [format-test-subject format-test-body format-batch-test-summary]

def main [] {
    print "Running tests for test email formatting and banner construction..."
    test-format-test-subject
    test-format-test-body
    test-format-batch-test-summary
    print "All formatting tests completed successfully!"
}

def test-format-test-subject [] {
    print "  Test: format-test-subject prepends [TEST] and strips accents..."

    let raw_subj = "Notificación de evaluación estadística"
    let formatted = (format-test-subject $raw_subj)
    assert ($formatted == "[TEST] Notificacion de evaluacion estadistica")

    # Already tagged with [TEST]
    let already_tagged = "[TEST] Reunion de departamento"
    let formatted_tagged = (format-test-subject $already_tagged)
    assert ($formatted_tagged == "[TEST] Reunion de departamento")

    print "  PASSED: format-test-subject"
}

def test-format-test-body [] {
    print "  Test: format-test-body includes banner, metadata and body..."

    let body = "Estimado equipo,\nFavor revisar el informe adjunto."
    let meta = {
        to: "colleagues@work.example.edu"
        subject: "Informe mensual"
        from: "user@work.example.edu"
        signature: "Author Name\nDirector de Escuela"
        attachments: ["https://drive.google.com/folder123"]
    }

    let test_body = (format-test-body $body $meta)

    assert ($test_body | str contains "TEST EMAIL VERIFICATION")
    assert ($test_body | str contains "user@example.com")
    assert ($test_body | str contains "colleagues@work.example.edu")
    assert ($test_body | str contains "Informe mensual")
    assert ($test_body | str contains "user@work.example.edu")
    assert ($test_body | str contains "https://drive.google.com/folder123")
    assert ($test_body | str contains "Estimado equipo")
    assert ($test_body | str contains "Director de Escuela")

    print "  PASSED: format-test-body"
}

def test-format-batch-test-summary [] {
    print "  Test: format-batch-test-summary handles multiple recipients..."

    let recipients = [
        "student1@students.work.example.edu"
        "student2@students.work.example.edu"
        "student3@students.work.example.edu"
    ]
    let subject = "Calificaciones finales"
    let sample_body = "Estimado/a estudiante, sus notas estan disponibles."

    let batch_summary = (format-batch-test-summary $recipients $subject $sample_body)

    assert ($batch_summary.total_recipients == 3)
    assert ($batch_summary.test_recipient == "user@example.com")
    assert ($batch_summary.test_subject == "[TEST] Calificaciones finales")
    assert ($batch_summary.banner | str contains "Batch Size:** 3 recipients")
    assert ($batch_summary.banner | str contains "student1@students.work.example.edu")
    assert ($batch_summary.banner | str contains "student2@students.work.example.edu")
    assert ($batch_summary.banner | str contains "student3@students.work.example.edu")

    print "  PASSED: format-batch-test-summary"
}
