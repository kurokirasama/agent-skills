# process_paper.nu
# Script to download and extract content from a scientific paper

export def download-paper [url: string, output_path: path] {
    # Attempt to download the PDF using wget or curl
    # In a real scenario, we'd use wget/curl. 
    # For this script, we'll simulate it or use a simple system call.
    let res = ^wget "-O" $output_path $url | complete
    if ($res.exit_code != 0) {
        return { success: false, error: $res.stderr }
    }
    return { success: true }
}

export def extract-content [pdf_path: path] {
    # Attempt to extract text using pdf-to-markdown or pdftotext
    # Since pdf-to-markdown is a tool for the agent, we'll use pdftotext as a fallback/primary in this script.
    let txt_path = $pdf_path | str replace '.pdf' '.txt'
    let res = ^pdftotext $pdf_path $txt_path | complete
    if ($res.exit_code != 0) {
        return { success: false, error: $res.stderr }
    }
    let content = open $txt_path
    return { success: true, content: $content }
}