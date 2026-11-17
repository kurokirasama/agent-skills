# Test script for attachment logic
def test_folder_creation_logic [] {
  let name = "project-x"
  let date = date now | format date "%Y_%m_%d"
  let expected = $"()_()"
  # Stub check
  assert equal  $"()_project-x"
}