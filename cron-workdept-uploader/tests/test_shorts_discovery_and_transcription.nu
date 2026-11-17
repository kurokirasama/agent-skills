use std assert
use ../scripts/pipeline.nu [select-published-video parse-srt-subtitles transcribe-video-srt]

def main [] {
    print "Running tests for published video discovery and SRT transcription..."
    test-select-published-video-local
    test-select-published-video-state-weighting
    test-parse-srt-subtitles
    test-transcribe-video-srt-dry-run
    print "All discovery and transcription tests passed successfully!"
}

def test-select-published-video-local [] {
    print "  Test: select-published-video selects from local directory..."
    let tmp = (mktemp -d)
    "dummy1" | save ($tmp | path join "video_A.mp4")
    "dummy2" | save ($tmp | path join "video_B.mp4")

    let state = { shorts: {} }
    let candidate = (select-published-video $tmp $state)

    assert ($candidate != null)
    assert ($candidate.source == "local")
    assert ($candidate.path =~ "video_[AB]\\.mp4")
    assert ($candidate.filename =~ "video_[AB]\\.mp4")

    rm -r $tmp
    print "  PASSED: select-published-video local selection"
}

def test-select-published-video-state-weighting [] {
    print "  Test: select-published-video prioritizes videos with fewer shorts..."
    let tmp = (mktemp -d)
    "dummy1" | save ($tmp | path join "video_old.mp4")
    "dummy2" | save ($tmp | path join "video_new.mp4")

    # video_old has 3 shorts, video_new has 0 shorts
    let state = {
        shorts: {
            "video_old": [
                { start: "00:00:10", end: "00:00:40" },
                { start: "00:01:00", end: "00:01:35" },
                { start: "00:02:10", end: "00:02:45" }
            ]
        }
    }
    let candidate = (select-published-video $tmp $state)

    assert ($candidate != null)
    # Must prioritize video_new
    assert ($candidate.stem == "video_new")

    rm -r $tmp
    print "  PASSED: select-published-video state weighting"
}

def test-parse-srt-subtitles [] {
    print "  Test: parse-srt-subtitles parses SRT blocks accurately..."
    let sample_srt = "1\n00:00:01,500 --> 00:00:05,200\nBienvenidos a la presentación de tesis.\n\n2\n00:00:05,800 --> 00:00:10,100\nEl objetivo principal fue predecir la inflación con redes neuronales.\n\n3\n00:00:10,500 --> 00:00:15,000\nLos resultados mostraron una precisión del 94%.\n"

    let parsed = (parse-srt-subtitles $sample_srt)
    assert (($parsed | length) == 3)
    assert (($parsed | get 0.start) == "00:00:01")
    assert (($parsed | get 0.end) == "00:00:05")
    assert (($parsed | get 0.text) =~ "Bienvenidos")

    assert (($parsed | get 1.start) == "00:00:05")
    assert (($parsed | get 1.end) == "00:00:10")
    assert (($parsed | get 1.text) =~ "redes neuronales")

    assert (($parsed | get 2.start) == "00:00:10")
    assert (($parsed | get 2.end) == "00:00:15")
    assert (($parsed | get 2.text) =~ "94%")

    print "  PASSED: parse-srt-subtitles"
}

def test-transcribe-video-srt-dry-run [] {
    print "  Test: transcribe-video-srt dry-run simulation..."
    let tmp = (mktemp -d)
    let fake_video = ($tmp | path join "test_vid.mp4")
    "fake video binary" | save $fake_video

    let srt_blocks = (transcribe-video-srt $fake_video --dry-run)
    assert (($srt_blocks | length) > 0)
    assert ("start" in ($srt_blocks | first))
    assert ("end" in ($srt_blocks | first))
    assert ("text" in ($srt_blocks | first))

    rm -r $tmp
    print "  PASSED: transcribe-video-srt dry-run"
}
