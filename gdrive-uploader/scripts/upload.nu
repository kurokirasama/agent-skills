#!/usr/bin/env nu

# Uploads files to a Google Drive folder using rclone and a folder ID.
# Usage: upload.nu <folder_id> <files...>

def main [folder_id: string, ...files: string] {
    if ($files | is-empty) {
        print "Error: No files specified for upload."
        exit 1
    }

    print $"Starting upload of ($files | length) files to folder ID: ($folder_id)..."

    for file in $files {
        if not ($file | path exists) {
            print $"Warning: File ($file) does not exist. Skipping."
            continue
        }

        print $"Uploading ($file)..."
        let result = do -i { ^rclone copy $file gdrive: --drive-root-folder-id $folder_id } | complete
        
        if $result.exit_code != 0 {
            print $"Error uploading ($file): ($result.stderr)"
        } else {
            print $"Successfully uploaded ($file)"
        }
    }
    
    print "Upload process finished."
}