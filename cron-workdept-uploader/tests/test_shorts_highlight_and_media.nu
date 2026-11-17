use std assert
use ../scripts/pipeline.nu [
    time-str-to-seconds
    seconds-to-time-str
    is-interval-overlapping
    calculate-1x1-crop-params
    select-shorts-highlight
    record-short-state
]

def main [] {
    print "Running tests for Shorts highlight extraction, media editing, and deduplication..."
    test-time-conversions
    test-interval-overlapping
    test-calculate-1x1-crop-params
    test-select-shorts-highlight-dry-run
    test-record-short-state
    print "All highlight and media tests passed successfully!"
}

def test-time-conversions [] {
    print "  Test: time-str-to-seconds and seconds-to-time-str conversions..."
    assert ((time-str-to-seconds "00:00:45") == 45)
    assert ((time-str-to-seconds "00:01:30") == 90)
    assert ((time-str-to-seconds "01:05:05") == 3905)

    assert ((seconds-to-time-str 45) == "00:00:45")
    assert ((seconds-to-time-str 90) == "00:01:30")
    assert ((seconds-to-time-str 3905) == "01:05:05")
    print "  PASSED: time conversions"
}

def test-interval-overlapping [] {
    print "  Test: interval overlapping detection..."
    let existing = [
        { start_sec: 10, end_sec: 45 }
        { start_sec: 120, end_sec: 160 }
    ]

    # Overlaps with first interval [10, 45]
    assert (is-interval-overlapping { start_sec: 20, end_sec: 50 } $existing)
    assert (is-interval-overlapping { start_sec: 5, end_sec: 15 } $existing)
    assert (is-interval-overlapping { start_sec: 15, end_sec: 30 } $existing)

    # Disjoint intervals
    assert (not (is-interval-overlapping { start_sec: 50, end_sec: 90 } $existing))
    assert (not (is-interval-overlapping { start_sec: 165, end_sec: 200 } $existing))
    print "  PASSED: interval overlapping"
}

def test-calculate-1x1-crop-params [] {
    print "  Test: 1:1 crop parameter calculation..."
    # 1920x1080 horizontal video
    let p1 = (calculate-1x1-crop-params 1920 1080)
    assert ($p1.size == "1080:1080")
    # (1920 - 1080) / 2 = 420
    assert ($p1.left == "420")
    assert ($p1.top == "0")

    # 1280x720 video
    let p2 = (calculate-1x1-crop-params 1280 720)
    assert ($p2.size == "720:720")
    # (1280 - 720) / 2 = 280
    assert ($p2.left == "280")
    assert ($p2.top == "0")

    print "  PASSED: 1:1 crop parameters"
}

def test-select-shorts-highlight-dry-run [] {
    print "  Test: select-shorts-highlight dry-run and duration limits..."
    let srt_blocks = [
        { index: 1, start: "00:00:05", end: "00:00:15", text: "Introducción y motivación del proyecto." }
        { index: 2, start: "00:00:15", end: "00:00:50", text: "El resultado central muestra una predicción del 95% con redes neuronales." }
        { index: 3, start: "00:00:50", end: "00:01:20", text: "Conclusiones finales y trabajo futuro." }
    ]

    let highlight = (select-shorts-highlight $srt_blocks [] --dry-run)
    assert ("start_time" in $highlight)
    assert ("end_time" in $highlight)
    assert ($highlight.duration >= 20 and $highlight.duration <= 60)
    assert ("hook" in $highlight)
    assert ("hashtags" in $highlight)
    print "  PASSED: select-shorts-highlight dry-run"
}

def test-record-short-state [] {
    print "  Test: record-short-state persists non-overlapping entries..."
    let tmp = (mktemp -d)
    let state_file = ($tmp | path join "state.json")
    { videos: {}, shorts: {} } | save $state_file

    let entry = {
        start_time: "00:00:15"
        end_time: "00:00:50"
        start_sec: 15
        end_sec: 50
        duration: 35
        short_id: "SH_12345"
        title: "Test Short"
        uploaded_at: "2026-10-07T12:00:00Z"
    }

    let updated_state = (record-short-state $state_file "video_A" $entry)
    assert ("shorts" in $updated_state)
    assert ("video_A" in $updated_state.shorts)
    assert (($updated_state.shorts.video_A | length) == 1)
    assert (($updated_state.shorts.video_A | get 0.short_id) == "SH_12345")

    rm -r $tmp
    print "  PASSED: record-short-state"
}
