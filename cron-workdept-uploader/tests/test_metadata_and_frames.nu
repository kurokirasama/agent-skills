use std assert
use ../scripts/pipeline.nu [parse-thesis-filename build-thesis-metadata select-best-frame]

def main [] {
    print "Running tests for thesis metadata construction and frame selection..."
    test-build-thesis-metadata
    test-select-best-frame
    print "All metadata and frame tests passed successfully!"
}

def test-build-thesis-metadata [] {
    print "  Test: build-thesis-metadata formatting..."
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
    assert ($meta.title == "Datos vs Leucemia Infantil | Proyecto de Título SUBJECT WORK")
    assert ($meta.description =~ "Proyecto de Título de Aniger Cid")
    assert ($meta.description =~ "2024")
    assert ($meta.description =~ "#SUBJECT #WORK #ProyectoDeTitulo")
    assert ($meta.categoryId == "27")
    assert ($meta.tags | any { |t| $t == "SUBJECT" })
    assert ($meta.tags | any { |t| $t == "Work University" })
    assert ($meta.tags | any { |t| $t == "2024" })

    # Check total length of tags is under 500 chars (YouTube tag limit)
    let tag_str = ($meta.tags | str join ",")
    assert (($tag_str | str length) <= 500)

    print "  PASSED: build-thesis-metadata"
}

def test-select-best-frame [] {
    print "  Test: select-best-frame heuristic..."
    # Create two temporary dummy files of different sizes to test selection heuristic
    let f1 = "/tmp/test_thumb_1.jpg"
    let f2 = "/tmp/test_thumb_2.jpg"
    "12345" | save -f $f1
    "1234567890" | save -f $f2

    let best = (select-best-frame [$f1, $f2])
    assert ($best == $f2)

    rm -f $f1 $f2
    print "  PASSED: select-best-frame"
}
