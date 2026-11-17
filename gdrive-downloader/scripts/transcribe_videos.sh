#!/usr/bin/env bash
# Generalized Whisper batch transcriber mirroring directory structure.
# Usage: transcribe_videos.sh <videos_base_dir> <transcriptions_out_dir> <language> <log_file> [download_log_file]
set -u

if [ "$#" -lt 4 ]; then
	echo "Usage: $0 <videos_base_dir> <transcriptions_out_dir> <language> <log_file> [download_log_file]" >&2
	exit 1
fi

VIDEOS_BASE="$1"
OUT_BASE="$2"
LANG="$3"
LOG="$4"
DOWNLOAD_LOG="${5:-}"

mkdir -p "$OUT_BASE" "$(dirname "$LOG")"
: >"$LOG"

# Wait for download DONE marker if download_log_file is provided and exists
if [ -n "$DOWNLOAD_LOG" ] && [ "$DOWNLOAD_LOG" != "-" ]; then
	echo "Waiting for downloads to complete in $DOWNLOAD_LOG..."
	while ! grep -q "^DONE" "$DOWNLOAD_LOG" 2>/dev/null; do
		sleep 15
	done
	sleep 5
fi

find "$VIDEOS_BASE" -type f -name "*.mp4" 2>/dev/null | sort | while IFS= read -r v; do
	rel=$(dirname "${v#$VIDEOS_BASE/}")
	if [ "$rel" = "." ] || [ -z "$rel" ]; then
		out="$OUT_BASE"
	else
		out="$OUT_BASE/$rel"
	fi
	name=$(basename "$v" .mp4)

	# Skip existing transcription
	if [ -f "$out/$name.txt" ]; then
		echo "SKIP $v (already transcribed)" >>"$LOG"
		continue
	fi

	mkdir -p "$out"
	if whisper "$v" --model large-v3-turbo --language "$LANG" --output_format txt --output_dir "$out" --verbose False >>"$LOG" 2>&1; then
		echo "OK $v" >>"$LOG"
	else
		echo "FAIL $v" >>"$LOG"
	fi
done

echo "DONE_WHISPER $(date)" >>"$LOG"
