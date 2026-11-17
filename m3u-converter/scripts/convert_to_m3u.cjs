#!/usr/bin/env node

/**
 * M3U Playlist Generator
 * Converts JSON YouTube metadata to standard .m3u format.
 */

const fs = require('fs');
const path = require('path');

function convertFile(jsonPath) {
  try {
    const data = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
    if (!Array.isArray(data)) {
      throw new Error('JSON input must be an array of video objects.');
    }

    let m3uContent = '#EXTM3U\n';
    data.forEach(item => {
      // Expecting fields: title, artist, url (consistent with best_ch_music.json)
      const title = item.title || 'Unknown Title';
      const artist = item.artist || 'Unknown Artist';
      const url = item.url || '';

      if (url) {
        m3uContent += `#EXTINF:-1,${artist} - ${title}\n${url}\n`;
      }
    });

    const m3uPath = jsonPath.replace(/\.json$/, '.m3u');
    fs.writeFileSync(m3uPath, m3uContent, 'utf8');
    return m3uPath;
  } catch (error) {
    throw new Error(`Failed to convert ${jsonPath}: ${error.message}`);
  }
}

function main() {
  const args = process.argv.slice(2);
  if (args.length === 0) {
    console.error('Usage: convert_to_m3u.cjs <file_or_directory>');
    process.exit(1);
  }

  const target = args[0];
  if (!fs.existsSync(target)) {
    console.error(`Error: Path ${target} does not exist.`);
    process.exit(1);
  }

  const stats = fs.statSync(target);
  if (stats.isFile()) {
    if (target.endsWith('.json')) {
      try {
        const result = convertFile(target);
        console.log(`Successfully converted: ${target} -> ${result}`);
      } catch (err) {
        console.error(err.message);
        process.exit(1);
      }
    } else {
      console.error('Error: Input file must be a .json file.');
      process.exit(1);
    }
  } else if (stats.isDirectory()) {
    const files = fs.readdirSync(target).filter(f => f.endsWith('.json'));
    if (files.length === 0) {
      console.log('No JSON files found in directory.');
      return;
    }

    let successCount = 0;
    let failCount = 0;

    files.forEach(file => {
      const fullPath = path.join(target, file);
      try {
        convertFile(fullPath);
        successCount++;
      } catch (err) {
        console.error(err.message);
        failCount++;
      }
    });

    console.log(`Batch conversion complete: ${successCount} succeeded, ${failCount} failed.`);
  }
}

main();
