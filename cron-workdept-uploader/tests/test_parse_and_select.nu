use std assert
use ../scripts/pipeline.nu [parse-thesis-filename select-next-thesis]

def main [] {
    print "Running tests for thesis filename parsing and candidate selection..."
    test-parse-thesis-filename
    test-duplicate-final-preference
    test-selection-by-oldest-year
    test-skip-completed-videos
    print "All tests passed successfully!"
}

def test-parse-thesis-filename [] {
    print "  Test: parse-thesis-filename with various filenames..."

    # Test 1: Standard file with final
    let res1 = (parse-thesis-filename "2023_Descifrando_el_Futuro_con_Datos_-_Bastián_Astudillo_final.mp4")
    assert ($res1.year == 2023)
    assert ($res1.title == "Descifrando el Futuro con Datos")
    assert ($res1.student == "Bastián Astudillo")
    assert ($res1.final_rank == 1)

    # Test 2: Double underscore in title
    let res2 = (parse-thesis-filename "2022_Detective_de_Datos__COVID-19_-_Sample_Student_final_final.mp4")
    assert ($res2.year == 2022)
    assert ($res2.title == "Detective de Datos COVID-19")
    assert ($res2.student == "Student Name")
    assert ($res2.final_rank == 2)

    # Test 3: Multiple students
    let res3 = (parse-thesis-filename "2024_Matemáticas_que_Salvan_Vidas_-_Javiera_Medina_Y_Camila_Mel_final.mp4")
    assert ($res3.year == 2024)
    assert ($res3.title == "Matemáticas que Salvan Vidas")
    assert ($res3.student == "Javiera Medina Y Camila Mel")
    assert ($res3.final_rank == 1)

    print "  PASSED: filename parsing"
}

def test-duplicate-final-preference [] {
    print "  Test: deduplication prefers most final suffix..."
    let files = [
        "2022_Detective_de_Datos__COVID-19_-_Sample_Student_final.mp4"
        "2022_Detective_de_Datos__COVID-19_-_Sample_Student_final_final.mp4"
    ]
    let state = {videos: {}}
    let selected = (select-next-thesis $files $state)
    assert ($selected != null)
    assert ($selected.filename == "2022_Detective_de_Datos__COVID-19_-_Sample_Student_final_final.mp4")
    assert ($selected.final_rank == 2)
    print "  PASSED: final_final preference"
}

def test-selection-by-oldest-year [] {
    print "  Test: selection picks oldest year..."
    let files = [
        "2024_Datos_vs_Leucemia_Infantil_-_Aniger_Cid_final.mp4"
        "2023_Descifrando_el_Futuro_con_Datos_-_Bastián_Astudillo_final.mp4"
        "2022_Detective_de_Datos__COVID-19_-_Sample_Student_final_final.mp4"
    ]
    let state = {videos: {}}
    let selected = (select-next-thesis $files $state)
    assert ($selected != null)
    assert ($selected.year == 2022)
    assert ($selected.student == "Student Name")
    print "  PASSED: oldest year selection"
}

def test-skip-completed-videos [] {
    print "  Test: skip videos already completed in state..."
    let files = [
        "2022_Detective_de_Datos__COVID-19_-_Sample_Student_final_final.mp4"
        "2023_Descifrando_el_Futuro_con_Datos_-_Bastián_Astudillo_final.mp4"
    ]
    # Mark the 2022 video as completed in state
    let state = {
        videos: {
            "2022_Detective_de_Datos__COVID-19_-_Sample_Student_final_final": {
                status: "completed"
                video_id: "xyz123"
            }
        }
    }
    let selected = (select-next-thesis $files $state)
    assert ($selected != null)
    assert ($selected.year == 2023)
    assert ($selected.student == "Bastián Astudillo")
    print "  PASSED: skip completed videos"
}
