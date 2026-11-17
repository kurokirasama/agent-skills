# skills/review-evaluation/tests/test_mod.nu
# Self-check for review-evaluation mod.nu utilities.

use ../mod.nu *

let test_dir = "/tmp/test_review_eval"

mkdir $test_dir
mkdir $"($test_dir)/src"

# --- detect-language ---
"print('hello')" | save -f $"($test_dir)/src/main.py"
let result = detect-language $test_dir
if ($result.language != "python") {
    print $"FAIL detect-language: expected python, got ($result.language)"
    rm -rf $test_dir
    exit 1
}

# --- get-run-command ---
let cmd = get-run-command "python" "test.py"
if ($cmd != "python3 test.py") {
    print $"FAIL get-run-command: expected 'python3 test.py', got '($cmd)'"
    rm -rf $test_dir
    exit 1
}

let cmd_r = get-run-command "r" "test.R"
if ($cmd_r != "Rscript test.R") {
    print $"FAIL get-run-command: expected 'Rscript test.R', got '($cmd_r)'"
    rm -rf $test_dir
    exit 1
}

# --- update-grupos-json ---
let gj = "/tmp/test_grupos.json"
'[{"grupo":1,"integrantes":["A"],"analizado":false,"entregado":false},{"grupo":2,"integrantes":["B"],"analizado":false,"entregado":false}]'
    | save -f $gj
update-grupos-json $gj 1 "analizado" true
let updated = open --raw $gj | from json
if ($updated | get 0 | get analizado) != true {
    print "FAIL update-grupos-json: expected analizado=true for grupo 1"
    rm -rf $test_dir
    rm -f $gj
    exit 1
}
if ($updated | get 1 | get analizado) != false {
    print "FAIL update-grupos-json: expected analizado=false for grupo 2"
    rm -rf $test_dir
    rm -f $gj
    exit 1
}

rm -rf $test_dir
rm -f $gj

print "All tests passed"
