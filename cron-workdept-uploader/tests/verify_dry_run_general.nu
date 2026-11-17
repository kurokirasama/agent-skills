use std assert
use ../scripts/pipeline.nu [
    classify-video-type
    parse-video-metadata
    select-next-video
    build-video-metadata
    format-markdown-report
]

def main [] {
    print "Testing end-to-end general video dry-run simulation..."

    # Create dummy general video metadata
    let cand = (parse-video-metadata "seminario_deep_learning_2026.mp4")
    assert ($cand.type == "general")

    let summary = "Seminario avanzado sobre arquitecturas Transformer y redes neuronales convolucionales aplicadas a visión computacional en la industria."
    let meta = (build-video-metadata $cand $summary)

    assert ($meta.title =~ ' \| WORK DEPT$')
    assert (not ($meta.title =~ '_'))
    assert ($meta.description =~ "Work University")
    assert (not ($meta.description =~ "#ProyectoDeTitulo"))

    let simulated_run = {
        filename: $cand.filename
        type: $cand.type
        title: $meta.title
        student: $cand.student
        year: $cand.year
        url: "https://youtu.be/SIMULATED_GENERAL"
        video_id: "SIMULATED_GENERAL"
        thumbnail_uploaded: true
        description: $meta.description
        tags: $meta.tags
    }

    let report = (format-markdown-report $simulated_run)
    assert ($report =~ "# Cron Pulse Report: WORK DEPT Video Uploader \\(General\\)")
    assert ($report =~ "\\*\\*Type:\\*\\* general")
    assert (not ($report =~ "\\*\\*Student:\\*\\*"))

    print "General video dry-run simulation PASSED!"
}
