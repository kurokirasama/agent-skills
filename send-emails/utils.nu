# Utility functions for send-emails skill

export def create_drive_folder [name: string] {
  let date = date now | format date "%Y_%m_%d"
  let folder_name = $"($date)_($name)"
  # Placeholder for Drive MCP folder creation
  print $"Creating folder ($folder_name) in Google Drive Public directory..."
  return $folder_name
}

export def mount_and_transfer [folder_name: string, files: list = []] {
  # Step 1: Verify if already mounted
  let disk = sys disks | where mount == "~/rclone/gdrive"
  if ($disk | is-empty) {
    print "Mounting drive..."
    rclone mount gdrive: ~/rclone/gdrive/ --daemon
    sleep 10sec
    
    # Re-verify if mounted
    let disk_check = sys disks | where mount == "~/rclone/gdrive"
    if ($disk_check | is-empty) {
      print "Mount failed after retry..."
      return
    }
  }
  
  let target = $"($env.HOME)/rclone/gdrive/Public/($folder_name)"
  mkdir $target
  for file in $files {
    cp $file $target
  }
  print "Transfer complete."
}

# Strips accents from Spanish characters per skill rules and ensures [TEST] prefix
export def format-test-subject [subject: string] {
  let stripped = (
    $subject
    | str replace -a 'á' 'a'
    | str replace -a 'é' 'e'
    | str replace -a 'í' 'i'
    | str replace -a 'ó' 'o'
    | str replace -a 'ú' 'u'
    | str replace -a 'Á' 'A'
    | str replace -a 'É' 'E'
    | str replace -a 'Í' 'I'
    | str replace -a 'Ó' 'O'
    | str replace -a 'Ú' 'U'
    | str replace -a 'ñ' 'n'
    | str replace -a 'Ñ' 'N'
  )
  if ($stripped | str starts-with "[TEST] ") {
    $stripped
  } else if ($stripped | str starts-with "[TEST]") {
    "[TEST] " + ($stripped | str substring 6..)
  } else {
    "[TEST] " + $stripped
  }
}

# Removes [TEST] prefix from subject for production dispatches
export def strip-test-prefix [subject: string] {
  if ($subject | str starts-with "[TEST] ") {
    $subject | str substring 7..
  } else if ($subject | str starts-with "[TEST]") {
    $subject | str substring 6..
  } else {
    $subject
  }
}

# Formats test email body by adding metadata banner at the top and preserving body & signature
export def format-test-body [body: string, meta: record] {
  let target_to = if ($meta | get -o to | is-empty) { "N/A" } else {
    let to_val = $meta.to
    if ($to_val | describe | str starts-with "list") {
      $to_val | str join ", "
    } else {
      $to_val | into string
    }
  }
  let target_subj = if ($meta | get -o subject | is-empty) { "N/A" } else { $meta.subject }
  let from_addr = if ($meta | get -o from | is-empty) { "default" } else { $meta.from }
  
  let attach_info = if ($meta | get -o attachments | is-empty) { "None" } else {
    let atts = $meta.attachments
    if ($atts | describe | str starts-with "list") {
      $atts | str join ", "
    } else {
      $atts | into string
    }
  }
  
  let banner = [
    "> [!IMPORTANT]"
    "> **TEST EMAIL VERIFICATION**"
    ("> - **Target Recipient(s):** " + $target_to)
    ("> - **Target Subject:** " + $target_subj)
    ("> - **Sender Profile:** " + $from_addr)
    ("> - **Attachments:** " + $attach_info)
    ">"
    "> *This is an automated test dispatch sent exclusively to `user@example.com` for review and approval before production transmission.*"
    "---"
    ""
  ] | str join "\n"
  
  mut full_body = $banner + "\n" + $body
  
  if ($meta | get -o signature | is-not-empty) {
    $full_body = $full_body + "\n\n" + $meta.signature
  }
  
  $full_body
}

# Formats a single representative test email summary for a batch send
export def format-batch-test-summary [recipients: list, template_subject: string, sample_body: string] {
  let total = ($recipients | length)
  let test_subj = format-test-subject $template_subject
  
  let rec_lines = ($recipients | each { |r| ">   - " + $r } | str join "\n")
  
  let banner = [
    "> [!IMPORTANT]"
    "> **BATCH TEST EMAIL VERIFICATION**"
    ("> - **Batch Size:** " + ($total | into string) + " recipients")
    ("> - **Target Subject:** " + $template_subject)
    "> - **Target Recipients List:**"
    $rec_lines
    ">"
    "> *This is a single representative test dispatch sent exclusively to `user@example.com` summarizing all target recipients before bulk production transmission.*"
    "---"
  ] | str join "\n"
  
  {
    total_recipients: $total
    test_recipient: "user@example.com"
    test_subject: $test_subj
    banner: $banner
    sample_body: $sample_body
  }
}

# Creates a test dispatch payload strictly routing to user@example.com
export def create-test-dispatch [input: record] {
  let test_subj = format-test-subject $input.subject
  let test_body = format-test-body $input.body $input

  {
    stage: "test"
    recipient: "user@example.com"
    subject: $test_subj
    body: $test_body
    original_target: $input
  }
}

# Handles approval, rejection, and revision decision transitions
export def handle-approval-decision [
  test_dispatch: record,
  decision: string,
  corrections?: record
] {
  if $decision == "approve" {
    let orig = $test_dispatch.original_target
    let to_list = if ($orig.to | describe | str starts-with "list") {
      $orig.to
    } else {
      [$orig.to]
    }
    
    let prod_body = if ($orig | get -o signature | is-not-empty) {
      $orig.body + "\n\n" + $orig.signature
    } else {
      $orig.body
    }

    let payloads = ($to_list | each { |rec|
      mut p = {
        to: $rec
        subject: (strip-test-prefix $orig.subject)
        body: $prod_body
      }
      if ($orig | get -o from | is-not-empty) {
        $p = ($p | insert from $orig.from)
      }
      if ($orig | get -o attachments | is-not-empty) {
        $p = ($p | insert attachments $orig.attachments)
      }
      $p
    })

    {
      status: "approved"
      ready_for_production: true
      payloads: $payloads
    }
  } else if $decision == "reject" {
    {
      status: "rejected"
      ready_for_production: false
      needs_revision: true
    }
  } else if $decision == "revise" {
    let orig = $test_dispatch.original_target
    let patch = if ($corrections | is-empty) { {} } else { $corrections }
    let updated_target = ($orig | merge $patch)
    let next_dispatch = create-test-dispatch $updated_target

    {
      status: "revision_pending_test"
      ready_for_production: false
      next_test_dispatch: $next_dispatch
    }
  } else {
    error make { msg: ("Unknown approval decision: " + $decision) }
  }
}

# Safety guard ensuring production dispatches never occur without verified approval
export def guard-production-dispatch [approval_result: record] {
  let is_approved = (($approval_result | get -o ready_for_production) == true) and (($approval_result | get -o status) == "approved")
  if not $is_approved {
    error make { msg: "PRODUCTION DISPATCH BLOCKED: Test email has not been approved by user." }
  }
  true
}