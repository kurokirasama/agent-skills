#!/usr/bin/env bash
# Generalized yt-dlp parallel downloader for restricted view-only Google Drive videos.
# Usage: download_videos.sh <tsv_file> <dest_base_dir> <log_file> [max_jobs]
set -u

if [ "$#" -lt 3 ]; then
	echo "Usage: $0 <tsv_file> <dest_base_dir> <log_file> [max_jobs]" >&2
	exit 1
fi

TSV="$1"
DEST_BASE="$2"
LOG="$3"
MAXJOBS="${4:-3}"

if [ ! -f "$TSV" ]; then
	echo "Error: TSV file '$TSV' not found" >&2
	exit 1
fi

mkdir -p "$DEST_BASE" "$(dirname "$LOG")"
: >"$LOG"

dl_one() {
	local id="$1" out_pattern="$2"
	mkdir -p "$(dirname "$out_pattern")"
	if yt-dlp -f "bestvideo*+bestaudio/best" --merge-output-format mp4 \
		--no-warnings --no-progress --retries 2 \
		-o "$out_pattern" "https://drive.google.com/file/d/$id/view" >>"$LOG" 2>&1; then
		echo "OK $id" >>"$LOG"
	else
		echo "FAIL $id" >>"$LOG"
	fi
}

while IFS=$'\t' read -r id rel_path; do
	[ -z "${id:-}" ] && continue
	if [ -n "${rel_path:-}" ]; then
		dir=$(dirname "$rel_path")
		if [ "$dir" = "." ] || [ -z "$dir" ]; then
			out="$DEST_BASE/%(title)s.%(ext)s"
		else
			out="$DEST_BASE/$dir/%(title)s.%(ext)s"
		fi
	else
		out="$DEST_BASE/%(title)s.%(ext)s"
	fi

	dl_one "$id" "$out" &

	while [ "$(jobs -rp | wc -l)" -ge "$MAXJOBS" ]; do
		wait -n
	done
done <"$TSV"

wait
echo "DONE $(date)" >>"$LOG"
