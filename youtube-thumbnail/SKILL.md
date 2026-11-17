---
name: youtube-thumbnail
description: Create, edit, and optimize 16:9 YouTube video thumbnails and covers (1280x720) with strict composition hierarchy, restrained typography, safe zone margins, and photo preservation rules.
---

# YouTube Thumbnail

Create clean, high-impact 16:9 YouTube thumbnails and video covers built around one strong idea. Emphasize hierarchy, curiosity, and an instantly readable focal point over visual clutter.

## Core Visual Rules

1. **Canvas Resolution**: Use 1280 x 720 (16:9 standard).
2. **One Dominant Focal Point**: Communicate the central promise of the video within roughly 1 second at mobile thumbnail size.
3. **Typography**:
   - Limit text to one short phrase (1 to 4 words).
   - Never repeat the full video title; provide an intrigue hook or core insight.
   - Use bold, high-contrast typography with minimal drop shadows. Avoid multiple competing fonts or decorative glow effects.
4. **Safe Zones & Margins**:
   - Keep vital graphics and text well clear of edges (at least 60px margin).
   - **Crucial**: Keep the bottom-right quadrant completely free of essential details or text to prevent obstruction by YouTube's timestamp badge.
5. **Color & Contrast**:
   - Use selective contrast and color separation.
   - Do not oversaturate or crush shadows. Preserve natural skin tones.
6. **Photo & Identity Preservation**:
   - When using portraits or photographs of real people, preserve the original pixels.
   - Never apply distorting generative edits, plastic AI smoothing, or artificial halos/rim lights around people.
   - Composite the subject over backgrounds with clean masking, uniform scaling, and a subtle natural drop shadow.

## Workflow

1. **Analyze Video Context**: Identify the core hook, title, topic, and whether a speaker/portrait is provided.
2. **Determine Graphic Composition**:
   - *Option A*: Single subject + clean contextual background.
   - *Option B*: Key visual object/diagram + high-impact 2-4 word hook.
3. **Assembly via PhotoCraft MCP or Image Tools**:
   - If the `photocraft` MCP server is available (`photocraft-cli mcp`):
     - Initialize canvas: `doc_new` (width: 1280, height: 720).
     - Layer background, graphical shapes, and text elements using `command_run`.
     - Render preview via `doc_render_preview` to inspect visual balance at thumbnail scale.
     - Save editable document as `.pcraft` via `doc_save`.
     - Export final thumbnail via `doc_export` (`thumbnail.png` or `thumbnail.jpg`).
   - If using Python/PIL or ImageMagick directly:
     - Composite background, overlays, and typography adhering strictly to the safe zone margins.
4. **Visual Quality Audit**:
   - Check legibility when scaled down to 200px width.
   - Verify timestamp area in bottom-right is clear.
   - Confirm colors remain natural and text has strong contrast.
