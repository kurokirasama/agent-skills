use std assert

# Import scaffold module
use ../scripts/scaffold_review_track.nu *

def main [] {
  print "Running test suite for peer-reviewer track scaffolding..."

  # Test 1: slugify
  assert ((slugify "Nature Communications") == "nature-communications")
  assert ((slugify "IEEE Transactions on Pattern Analysis and Machine Intelligence") == "ieee-transactions-on-pattern-analysis-and-machine-intelligence")
  assert ((slugify "Special Journal #1 2026!") == "special-journal-1-2026")

  # Test 2: generate-track-id
  let tid = (generate-track-id "Nature Communications" "20260911")
  assert ($tid == "peer_review_nature-communications_20260911")

  # Test 3: scaffold track artifacts in temporary folder
  let tmp_base = ($env.HOME | path join "tmp_test_peer_review")
  let target_tracks_dir = ($tmp_base | path join "conductor" "tracks")
  mkdir $target_tracks_dir

  let scaffold_res = (scaffold-review-track {
    manuscript_path: "/dummy/paper/draft.tex",
    journal_name: "IEEE TPAMI",
    aims_scope: "Pattern analysis, statistical machine learning, and computer vision.",
    author_guidelines: "Max 12 double-column pages, mandatory reproducible code links.",
    areas_of_concern: "Check statistical significance of Table 2 and novelty against 2025 baseline.",
    tracks_dir: $target_tracks_dir,
    date_str: "20260911"
  })

  assert ($scaffold_res.success == true)
  assert ($scaffold_res.track_dir | path exists)
  assert (($scaffold_res.track_dir | path join "spec.md") | path exists)
  assert (($scaffold_res.track_dir | path join "plan.md") | path exists)
  assert (($scaffold_res.track_dir | path join "howto.md") | path exists)
  assert (($scaffold_res.track_dir | path join "index.md") | path exists)
  assert (($scaffold_res.track_dir | path join "metadata.json") | path exists)

  # Check metadata content
  let meta = (open ($scaffold_res.track_dir | path join "metadata.json"))
  assert ($meta.track_id == "peer_review_ieee-tpami_20260911")
  assert ($meta.type == "feature")
  assert ($meta.status == "new")

  # Clean up test dir
  rm -rf $tmp_base
  print "All tests in test_track_scaffolding.nu passed successfully!"
}
