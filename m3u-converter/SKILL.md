---
name: m3u-converter
description: Converts JSON files containing YouTube video metadata into standard .m3u playlist files. Use when you need to generate playlists for media players from JSON data.
---

# M3U Playlist Generator

This skill converts JSON files structured with YouTube video metadata (title, artist, url) into standard .m3u playlist files.

## Workflow

1.  **Identify Input**: Determine the path to the JSON file or a directory containing multiple JSON files.
2.  **Conversion**: Use the provided script to perform the conversion.
3.  **Verification**: Confirm that the .m3u file has been created in the same directory as the source JSON.

## Commands

To convert a single file:
```bash
node skills/m3u-converter/scripts/convert_to_m3u.cjs <path_to_file.json>
```

To batch convert all JSON files in a directory:
```bash
node skills/m3u-converter/scripts/convert_to_m3u.cjs <path_to_directory>
```

## Data Format Consistency

The skill expects JSON files to be an array of objects with at least the following fields:
- `title`: The name of the song/video.
- `artist`: The name of the artist.
- `url`: The YouTube URL of the video.

Example input (`playlist.json`):
```json
[
  {
    "title": "Song Title",
    "artist": "Artist Name",
    "url": "https://www.youtube.com/watch?v=example"
  }
]
```

Example output (`playlist.m3u`):
```m3u
#EXTM3U
#EXTINF:-1,Artist Name - Song Title
https://www.youtube.com/watch?v=example
```