# persistence.nu
# Script to manage the last_updated date and processed_dois in update.json

export def get-update-data [research_dir: path] {
    let update_file = $research_dir | path join "update.json"
    
    if ($update_file | path exists) {
        return (open $update_file)
    } else {
        # Default data
        return {
            last_updated: ((date now) - 365day | format date "%Y-%m-%dT%H:%M:%S%z"),
            processed_dois: []
        }
    }
}

export def get-last-updated [research_dir: path] {
    let data = get-update-data $research_dir
    return ($data.last_updated | into datetime)
}

export def set-last-updated [research_dir: path, last_date: datetime] {
    let update_file = $research_dir | path join "update.json"
    mut data = get-update-data $research_dir
    
    $data.last_updated = ($last_date | format date "%Y-%m-%dT%H:%M:%S%z")
    
    # Ensure research_dir exists
    mkdir $research_dir
    
    $data | save -f $update_file
}

export def add-processed-doi [research_dir: path, doi: string] {
    let update_file = $research_dir | path join "update.json"
    mut data = get-update-data $research_dir
    
    if $doi not-in $data.processed_dois {
        $data.processed_dois = ($data.processed_dois | append $doi)
        mkdir $research_dir
        $data | save -f $update_file
    }
}

export def is-doi-processed [research_dir: path, doi: string] {
    let data = get-update-data $research_dir
    return ($doi in $data.processed_dois)
}