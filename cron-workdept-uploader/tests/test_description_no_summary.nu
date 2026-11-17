use std assert
use ../scripts/pipeline.nu [build-thesis-metadata build-general-metadata build-video-metadata extract-brief-insight]

def main [] {
    print "Running tests for YouTube descriptions without AI summary..."
    test-thesis-description-excludes-summary
    test-general-description-brief-insight
    test-hashtags-still-derived-from-summary
    test-brief-insight-helper
    print "All no-summary description tests passed successfully!"
}

def test-thesis-description-excludes-summary [] {
    print "  Test: thesis description contains NO AI summary text..."
    let parsed = {
        filename: "2024_Datos_vs_Leucemia_Infantil_-_Aniger_Cid_final.mp4"
        stem: "2024_Datos_vs_Leucemia_Infantil_-_Aniger_Cid_final"
        year: 2024
        title: "Datos vs Leucemia Infantil"
        student: "Aniger Cid"
        final_rank: 1
    }
    let summary = "Estudio epidemiológico sobre factores asociados a la supervivencia en leucemia infantil utilizando modelos de regresión de Cox y árboles de decisión."

    let meta = (build-thesis-metadata $parsed $summary)

    # The full AI summary must NOT appear in the description
    assert (not ($meta.description | str contains $summary))
    assert (not ($meta.description | str contains "árboles de decisión"))
    # Header line and institutional hashtags must remain
    assert ($meta.description | str contains "Proyecto de Título de Aniger Cid")
    assert ($meta.description | str contains "2024")
    assert ($meta.description | str contains "#SUBJECT #WORK #ProyectoDeTitulo")

    print "  PASSED: thesis-description-excludes-summary"
}

def test-general-description-brief-insight [] {
    print "  Test: general description contains brief insight, NOT full summary..."
    let parsed = {
        filename: "workshop_machine_learning_dia1.mp4"
        stem: "workshop_machine_learning_dia1"
        type: "general"
        year: null
        title: null
        student: null
        final_rank: 0
    }
    let summary = "Taller práctico sobre algoritmos de clasificación supervisada, árboles de decisión y validación cruzada para estudiantes y profesionales. En la segunda parte se revisan métricas de evaluación y despliegue de modelos en producción con ejemplos reales de la industria chilena."

    let meta = (build-general-metadata $parsed $summary)

    # The full AI summary must NOT appear verbatim in the description
    assert (not ($meta.description | str contains $summary))
    # Lead paragraph and institutional hashtags must remain
    assert ($meta.description | str contains "Work University")
    assert ($meta.description | str contains "#WORKDEPT #WORK #SUBJECT")
    assert (not ($meta.description | str contains "#ProyectoDeTitulo"))
    # A brief insight derived from the summary must be present and shorter than the full summary
    let brief = (extract-brief-insight $summary)
    assert (($brief | str length) < ($summary | str length))
    assert ($meta.description | str contains $brief)

    print "  PASSED: general-description-brief-insight"
}

def test-hashtags-still-derived-from-summary [] {
    print "  Test: hashtags still derived from AI summary analysis..."
    let thesis_cand = {
        filename: "2023_Descifrando_el_Futuro_con_Datos_-_Bastián_Astudillo_final.mp4"
        stem: "2023_Descifrando_el_Futuro_con_Datos_-_Bastián_Astudillo_final"
        type: "thesis"
        year: 2023
        title: "Descifrando el Futuro con Datos"
        student: "Bastián Astudillo"
        final_rank: 1
    }
    let thesis_meta = (build-video-metadata $thesis_cand "Análisis de series temporales y modelos predictivos.")
    # 2 topic hashtags + 3 institutional = 5 hashtags total
    let thesis_tags = ($thesis_meta.description | parse --regex '(#\S+)' | get capture0)
    assert (($thesis_tags | length) == 5)
    assert ($thesis_meta.description | str contains "#ProyectoDeTitulo")

    let general_cand = {
        filename: "charla_ia.mp4"
        stem: "charla_ia"
        type: "general"
        year: null
        title: null
        student: null
        final_rank: 0
    }
    let general_meta = (build-video-metadata $general_cand "Charla sobre inteligencia artificial generativa y ética.")
    let general_tags = ($general_meta.description | parse --regex '(#\S+)' | get capture0)
    assert (($general_tags | length) == 5)
    assert (not ($general_meta.description | str contains "#ProyectoDeTitulo"))

    print "  PASSED: hashtags-still-derived-from-summary"
}

def test-brief-insight-helper [] {
    print "  Test: extract-brief-insight returns short derived insight..."
    let summary = "Taller práctico sobre algoritmos de clasificación supervisada, árboles de decisión y validación cruzada. Segunda oración con más detalles extensos sobre el contenido del taller y sus aplicaciones."
    let brief = (extract-brief-insight $summary)
    # Must be shorter than the full summary and bounded
    assert (($brief | str length) < ($summary | str length))
    assert (($brief | str length) <= 220)
    assert (($brief | str trim | str length) > 0)
    # Empty summary falls back to a generic line, never empty
    let fallback = (extract-brief-insight "")
    assert (($fallback | str trim | str length) > 0)

    print "  PASSED: brief-insight-helper"
}
