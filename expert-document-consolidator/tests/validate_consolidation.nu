# Validation script for expert-document-consolidator
def main [] {
    print "Starting validation of expert-document-consolidator skill..."
    
    let sample_dir = "skills/expert-document-consolidator/tests/samples"
    let output_file = "consolidated_document.md"
    
    # Cleanup previous output
    if ($output_file | path exists) { rm $output_file }
    
    # Run the skill (assuming it's already linked or run via preset)
    # We use a direct prompt to trigger the skill behavior for testing
    print "Running skill..."
    gemini run -s expert-document-consolidator $"Consolidate the following files: (ls $sample_dir | get name | str join ' ')"
    
    if not ($output_file | path exists) {
        error make {msg: "Output file 'consolidated_document.md' was not created."}
    }
    
    let content = open --raw $output_file
    
    print "Checking for required elements..."
    
    # 1. Check for Index/TOC
    if ($content | str contains "Table of Contents") or ($content | str contains "Index") {
        print "✅ Table of Contents/Index found."
    } else {
        print "⚠️ Warning: No explicit Table of Contents/Index header found, but structure may exist."
    }
    
    # 2. Check for Zero-Loss (Key concepts from both docs)
    let required_concepts = [
        "superposition",
        "entanglement",
        "qubit",
        "spooky action at a distance",
        "0 and 1 simultaneously"
    ]
    
    for concept in $required_concepts {
let concept_lower = $concept | str lowercase
let content_lower = $content | str lowercase
        if ($content_lower | str contains $concept_lower) {
            print $"✅ Concept found: ($concept)"
        } else {
            error make {msg: $"Missing required concept: ($concept)"}
        }
    }
    
    # 3. Check for Narrative Flow (Introduction and Conclusion)
    if ($content | str contains "Introduction") and ($content | str contains "Conclusion") {
        print "✅ Introduction and Conclusion found."
    } else {
        error make {msg: "Missing Introduction or Conclusion."}
    }
    
    print "Validation successful!"
}