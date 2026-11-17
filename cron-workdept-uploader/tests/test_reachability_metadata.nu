use std assert
use ../scripts/pipeline.nu [generate-reachability-title build-general-metadata build-video-metadata]

def main [] {
    print "Running tests for reachability title and general metadata construction..."
    test-generate-reachability-title
    test-generate-reachability-title-fallback
    test-build-general-metadata
    test-build-video-metadata-dispatch
    print "All reachability metadata tests passed successfully!"
}

def test-generate-reachability-title [] {
    print "  Test: generate-reachability-title creates high-CTR hook title with branding suffix..."

    let summary = "En este seminario sobre modelos predictivos y series de tiempo aplicados a la economía, exploramos cómo predecir la inflación con redes neuronales y modelos ARIMA en Chile."
    let title = (generate-reachability-title $summary "charla_series_tiempo_2026")

    # Must end with institutional branding
    assert ($title =~ ' \| WORK DEPT$')

    # Total title length should be readable and under 100 characters (target < 70 chars)
    assert (($title | str length) <= 100)
    assert (($title | str length) >= 15)

    # Must not contain raw underscore separators or .mp4 extensions
    assert (not ($title =~ '_'))
    assert (not ($title =~ '\.mp4'))

    print "  PASSED: generate-reachability-title"
}

def test-generate-reachability-title-fallback [] {
    print "  Test: generate-reachability-title handles empty summary with clean fallback..."

    let title = (generate-reachability-title "" "conferencia_análisis_de_datos_avanzado")
    assert ($title == "Conferencia Análisis De Datos Avanzado | WORK DEPT")

    print "  PASSED: generate-reachability-title-fallback"
}

def test-build-general-metadata [] {
    print "  Test: build-general-metadata structure and formatting..."

    let parsed = {
        filename: "workshop_machine_learning_dia1.mp4"
        stem: "workshop_machine_learning_dia1"
        type: "general"
        year: null
        title: null
        student: null
        final_rank: 0
    }
    let summary = "Taller práctico sobre algoritmos de clasificación supervisada, árboles de decisión y validación cruzada para estudiantes y profesionales."

    let meta = (build-general-metadata $parsed $summary)

    # Title verification
    assert ($meta.title =~ ' \| WORK DEPT$')

    # Description verification
    assert ($meta.description =~ "Work University")
    assert ($meta.description =~ "#WORKDEPT")
    assert ($meta.description =~ "#WORK")
    assert ($meta.description =~ "#SUBJECT")
    # Must NOT include thesis-specific hashtag
    assert (not ($meta.description =~ "#ProyectoDeTitulo"))

    # Category and Tags verification
    assert ($meta.categoryId == "27")
    assert ($meta.tags | any { |t| $t == "ies work" })
    assert ($meta.tags | any { |t| $t == "SUBJECT" })
    assert ($meta.tags | any { |t| $t == "Work University" })

    # Tag length bound
    let tag_str = ($meta.tags | str join ",")
    assert (($tag_str | str length) <= 450)

    print "  PASSED: build-general-metadata"
}

def test-build-video-metadata-dispatch [] {
    print "  Test: build-video-metadata dispatches based on candidate.type..."

    let thesis_cand = {
        filename: "2023_Descifrando_el_Futuro_con_Datos_-_Bastián_Astudillo_final.mp4"
        stem: "2023_Descifrando_el_Futuro_con_Datos_-_Bastián_Astudillo_final"
        type: "thesis"
        year: 2023
        title: "Descifrando el Futuro con Datos"
        student: "Bastián Astudillo"
        final_rank: 1
    }
    let thesis_summary = "Análisis de series temporales y modelos predictivos."
    let thesis_meta = (build-video-metadata $thesis_cand $thesis_summary)
    assert ($thesis_meta.title == "Descifrando el Futuro con Datos | Proyecto de Título SUBJECT WORK")
    assert ($thesis_meta.description =~ "#ProyectoDeTitulo")

    let general_cand = {
        filename: "charla_ia.mp4"
        stem: "charla_ia"
        type: "general"
        year: null
        title: null
        student: null
        final_rank: 0
    }
    let general_summary = "Charla sobre inteligencia artificial generativa y ética."
    let general_meta = (build-video-metadata $general_cand $general_summary)
    assert ($general_meta.title =~ ' \| WORK DEPT$')
    assert (not ($general_meta.description =~ "#ProyectoDeTitulo"))

    print "  PASSED: build-video-metadata-dispatch"
}
