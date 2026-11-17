use std assert
use ../scripts/pipeline.nu [classify-video-type parse-video-metadata select-next-video]

def main [] {
    print "Running tests for video classification and thesis-priority selection..."
    test-classify-video-type
    test-parse-video-metadata
    test-thesis-priority-over-general
    test-general-selection-when-thesis-completed
    print "All classification and selection tests passed successfully!"
}

def test-classify-video-type [] {
    print "  Test: classify-video-type distinguishes thesis vs general..."

    # Thesis patterns
    assert ((classify-video-type "2023_Descifrando_el_Futuro_con_Datos_-_Bastián_Astudillo_final.mp4") == "thesis")
    assert ((classify-video-type "2022_Detective_de_Datos__COVID-19_-_Sample_Student_final_final.mp4") == "thesis")
    assert ((classify-video-type "2024_Matemáticas_que_Salvan_Vidas_-_Javiera_Medina_final.mp4") == "thesis")

    # General patterns
    assert ((classify-video-type "charla_series_de_tiempo_2026.mp4") == "general")
    assert ((classify-video-type "workshop_machine_learning_dia1.mp4") == "general")
    assert ((classify-video-type "seminario_investigacion_facultad.mp4") == "general")
    assert ((classify-video-type "tutorial_python_estadistica.mp4") == "general")

    print "  PASSED: classify-video-type"
}

def test-parse-video-metadata [] {
    print "  Test: parse-video-metadata unified record output..."

    let thesis_res = (parse-video-metadata "2023_Descifrando_el_Futuro_con_Datos_-_Bastián_Astudillo_final.mp4")
    assert ($thesis_res.type == "thesis")
    assert ($thesis_res.year == 2023)
    assert ($thesis_res.student == "Bastián Astudillo")
    assert ($thesis_res.title == "Descifrando el Futuro con Datos")

    let general_res = (parse-video-metadata "charla_series_de_tiempo_2026.mp4")
    assert ($general_res.type == "general")
    assert ($general_res.filename == "charla_series_de_tiempo_2026.mp4")
    assert ($general_res.stem == "charla_series_de_tiempo_2026")

    print "  PASSED: parse-video-metadata"
}

def test-thesis-priority-over-general [] {
    print "  Test: select-next-video prioritizes thesis videos over general videos..."

    let files = [
        "charla_general_antigua.mp4"
        "2023_Descifrando_el_Futuro_con_Datos_-_Bastián_Astudillo_final.mp4"
        "tutorial_reciente.mp4"
    ]
    let state = {videos: {}}
    let selected = (select-next-video $files $state)

    assert ($selected != null)
    assert ($selected.type == "thesis")
    assert ($selected.filename == "2023_Descifrando_el_Futuro_con_Datos_-_Bastián_Astudillo_final.mp4")

    print "  PASSED: thesis-priority-over-general"
}

def test-general-selection-when-thesis-completed [] {
    print "  Test: select-next-video selects general video when all thesis videos are completed..."

    let files = [
        "2023_Descifrando_el_Futuro_con_Datos_-_Bastián_Astudillo_final.mp4"
        "charla_series_de_tiempo_2026.mp4"
    ]
    let state = {
        videos: {
            "2023_Descifrando_el_Futuro_con_Datos_-_Bastián_Astudillo_final": {
                status: "completed"
                video_id: "xyz123"
            }
        }
    }
    let selected = (select-next-video $files $state)

    assert ($selected != null)
    assert ($selected.type == "general")
    assert ($selected.filename == "charla_series_de_tiempo_2026.mp4")

    print "  PASSED: general-selection-when-thesis-completed"
}
