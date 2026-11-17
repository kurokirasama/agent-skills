#!/usr/bin/env python3
"""Generates Obsidian-flavored markdown retrospective notes from parsed session transcripts."""
import sys
import os

# Guarantee UTF-8 locale for spawned subshells (draft 2026-08-29 obs 2):
# non-login cron/AppImage envs may lack locale vars and break subprocesses.
os.environ.setdefault("LC_ALL", "C.UTF-8")
os.environ.setdefault("LANG", "C.UTF-8")
import json
import argparse
from datetime import datetime
import subprocess
import re

# Import the parser function
from transcript_parser import parse_transcript

def get_active_track_slug(tracks_file=None):
    """Detect the active or most recently completed Conductor track and return its slug.

    Args:
        tracks_file: Path to the conductor tracks.md registry. Defaults to local ./conductor/tracks.md.

    Returns:
        A lowercase, underscore-separated slug string derived from the track description,
        or 'session_retrospective' as a fallback.
    """
    conductor_dir = None
    if tracks_file is not None:
        conductor_dir = os.path.dirname(os.path.abspath(tracks_file))
    else:
        # Walk up to find conductor directory
        curr = os.getcwd()
        while True:
            candidate = os.path.join(curr, "conductor")
            if os.path.isdir(candidate):
                conductor_dir = candidate
                tracks_file = os.path.join(candidate, "tracks.md")
                break
            parent = os.path.dirname(curr)
            if parent == curr:
                break
            curr = parent
        if conductor_dir is None:
            # Fallback
            conductor_dir = os.path.join(os.getcwd(), "conductor")
            tracks_file = os.path.join(conductor_dir, "tracks.md")

    active_line = None
    if os.path.exists(tracks_file):
        try:
            with open(tracks_file, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            # 1. Search for the active track line containing [~]
            for line in lines:
                if '[~]' in line:
                    active_line = line.strip()
                    break
                    
            # 2. If no active track, look for the most recently completed track ([x] or [X]) in reverse order
            if not active_line:
                for line in reversed(lines):
                    if '[x]' in line or '[X]' in line:
                        active_line = line.strip()
                        break
        except Exception as e:
            print(f"Warning: Exception reading tracks_file: {e}")

    # 3. If no active or completed track, look at archived tracks
    if not active_line and os.path.isdir(os.path.join(conductor_dir, "archive")):
        archive_dir = os.path.join(conductor_dir, "archive")
        try:
            entries = []
            for entry in os.listdir(archive_dir):
                full_path = os.path.join(archive_dir, entry)
                if os.path.isdir(full_path):
                    entries.append((full_path, os.path.getmtime(full_path), entry))
            if entries:
                # Sort by modification time descending
                entries.sort(key=lambda x: x[1], reverse=True)
                archived_folder_name = entries[0][2]
                # Clean up date suffix, e.g. _20260611 or -20260611
                import re
                slug = re.sub(r'[_\-]\d{8}$', '', archived_folder_name)
                # Ensure it's lowercase, underscore-separated, and limited
                slug = slug.lower().replace(' ', '_').replace(':', '').replace('(', '').replace(')', '').replace('-', '_')
                slug = "".join([c for c in slug if c.isalnum() or c == '_'])
                return slug[:50]
        except Exception as e:
            print(f"Warning: Exception reading archived tracks: {e}")

    # 4. If we found an active/completed track line, parse it
    if active_line:
        try:
            # Check for direct tracks/ link first (Format A or Format B with link)
            m_link = re.search(r'tracks/([^/\s\)]+)', active_line)
            if m_link:
                track_slug = m_link.group(1)
                # Strip date suffix e.g. _20260611 or -20260611
                track_slug = re.sub(r'[_\-]\d{8}$', '', track_slug)
                return track_slug[:50]
                
            # Try Format B
            # Pattern: - [ ] **Track: Title**
            m = re.search(r'-\s*\[[\s~xX]\]\s*\*\*Track:\s*(.*?)\*\*', active_line)
            if m:
                track_desc = m.group(1).strip()
            else:
                # Try to extract from general markdown link pattern if present
                link_match = re.search(r'\[([^\]]+)\]\(([^)]+)\)', active_line)
                if link_match:
                    url = link_match.group(2).strip()
                    if 'tracks/' in url:
                        track_part = url.split('tracks/')[-1].strip('/')
                        track_desc = track_part.split('/')[0] if '/' in track_part else track_part
                    else:
                        track_desc = link_match.group(1).strip()
                else:
                    # Fallback: strip the checkbox
                    track_desc = re.sub(r'^-\s*\[[\s~xX]\]\s*', '', active_line).strip()
                
            # Convert description to slug
            slug = track_desc.lower().replace(' ', '_').replace(':', '').replace('(', '').replace(')', '').replace('-', '_')
            slug = "".join([c for c in slug if c.isalnum() or c == '_'])
            return slug[:50]
        except Exception as e:
            print(f"Warning: Exception parsing track line: {e}")

    return "session_retrospective"

def get_recent_commits(project_dir):
    """Get the recent git commits for the session.

    Checks for commits since 12 hours ago. If none, falls back to the last 5 commits.
    """
    try:
        # Check if it's a git repo
        res = subprocess.run(
            ["git", "-C", project_dir, "rev-parse", "--is-inside-work-tree"],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True
        )
        if res.stdout.strip() != "true":
            return None
    except Exception:
        return None

    try:
        # Commit log since 12 hours ago
        res = subprocess.run(
            ["git", "-C", project_dir, "log", "--since=12 hours ago", "--oneline"],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True
        )
        commits = res.stdout.strip()
        if commits:
            return f"### Commits in the last 12 hours:\n\n```text\n{commits}\n```"

        # Fallback: Last 5 commits
        res = subprocess.run(
            ["git", "-C", project_dir, "log", "-n", "5", "--oneline"],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True
        )
        last_commits = res.stdout.strip()
        if last_commits:
            return f"### No commits in the last 12 hours. Last 5 commits:\n\n```text\n{last_commits}\n```"

        return "No commits found in the repository."
    except Exception as e:
        return f"Error retrieving git commits: {e}"
def get_obsidian_vault_root():
    """Resolve the Obsidian vault root path, querying Nushell config if needed."""
    # 1. Check environment variable first to avoid expensive subprocess call
    val = os.environ.get("OBSIDIAN_VAULT_ROOT")
    if val:
        return os.path.expanduser(val)
        
    # 2. Check if default fallback exists to avoid subprocess call
    default_fallback = os.path.expanduser("~/obsidian/vaults") # generalized fallback
    if os.path.isdir(default_fallback):
        return default_fallback

    # 3. Query Nushell only as last resort with a timeout
    try:
        # Query Nushell to get the vault path defined in the user's config/env
        res = subprocess.run(
            ["nu", "--config", os.path.expanduser("~/.config/nushell/config.nu"),
             "--env-config", os.path.expanduser("~/.config/nushell/env.nu"),
             "-c", "print $'__VAULT_ROOT__(try { $env.MY_ENV_VARS.OBSIDIAN_VAULT_ROOT } catch { $env.OBSIDIAN_VAULT_ROOT? | default \"\" })__VAULT_ROOT__'"],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=10
        )
        if res.returncode == 0:
            import re
            m = re.search(r'__VAULT_ROOT__(.*?)__VAULT_ROOT__', res.stdout, re.DOTALL)
            if m:
                val = m.group(1).strip()
                if val:
                    val = val.strip('"\'')
                    return os.path.expanduser(val)
    except Exception:
        pass
    
    return default_fallback

def get_project_slug(project_dir, vault_path=None):
    """Detect project name and generate its slug, matching longterm-memory-writer mod.nu."""
    if not vault_path:
        vault_path = get_obsidian_vault_root()
        
    # Check if a matching note exists in AGENTS_MEMORY/ to resolve collision-resolved slugs
    if vault_path:
        vault_root = os.path.expanduser(vault_path)
        if os.path.basename(vault_root) == "INSIGHTS":
            vault_root = os.path.dirname(vault_root)
        agents_memory_dir = os.path.join(vault_root, "AGENTS_MEMORY")
        
        if os.path.isdir(agents_memory_dir):
            try:
                target_path_norm = os.path.abspath(os.path.expanduser(project_dir))
                for entry in os.listdir(agents_memory_dir):
                    dir_path = os.path.join(agents_memory_dir, entry)
                    if os.path.isdir(dir_path):
                        index_file = os.path.join(dir_path, f"{entry}.md")
                        if os.path.isfile(index_file):
                            try:
                                with open(index_file, 'r', encoding='utf-8') as f:
                                    content = f.read()
                                # Parse YAML frontmatter using regex to avoid external PyYAML dependency
                                m = re.match(r'\A---\r?\n(.*?)\r?\n---', content, re.DOTALL)
                                if m:
                                    fm_content = m.group(1)
                                    path_match = re.search(r'(?m)^absolute_path:\s*["\']?(.*?)["\']?\s*$', fm_content)
                                    if path_match:
                                        fm_path = path_match.group(1)
                                        fm_path_norm = os.path.abspath(os.path.expanduser(fm_path))
                                        if fm_path_norm == target_path_norm:
                                            # Match found! Return the slug from folder name
                                            return entry
                            except Exception as e:
                                print(f"Warning: Exception reading memory index {index_file}: {e}")
            except Exception as e:
                print(f"Warning: Exception scanning AGENTS_MEMORY directory: {e}")

    product_md = os.path.join(project_dir, "conductor", "product.md")
    project_name = os.path.basename(project_dir)
    
    if os.path.exists(product_md):
        try:
            with open(product_md, 'r', encoding='utf-8') as f:
                content = f.read()
            m = re.search(r'(?m)^# Product Definition:\s*(.*)$', content)
            if m:
                project_name = m.group(1).strip()
        except Exception as e:
            print(f"Warning: Exception parsing product.md: {e}")
            
    # Slugify: downcase, replace spaces/hyphens with underscores, remove non-alnum/non-underscore
    slug = project_name.lower().replace(' ', '_').replace('-', '_')
    slug = re.sub(r'[^a-z0-9_]', '', slug)
    if not slug:
        slug = "project"
    return slug


def generate_retro_note(transcript_path, vault_path=None, slug=None, open_in_obsidian=False, project_slug=None):
    """Generate a structured Obsidian retrospective note from a session transcript.

    Args:
        transcript_path: Absolute path to the transcript.jsonl file.
        vault_path: Optional absolute path to the target Obsidian vault folder (INSIGHTS/). Resolved from environment if not provided.
        slug: Optional descriptive slug for the note filename. Auto-detected if not provided.
        open_in_obsidian: If True, attempts to open the note in the Obsidian desktop app.
        project_slug: Optional slug of the long-term memory note for automated cross-linking.

    Returns:
        The absolute path to the generated markdown note file.
    """
    # Resolve project_dir
    project_dir = None
    curr = os.getcwd()
    while True:
        if os.path.exists(os.path.join(curr, "conductor")) or os.path.exists(os.path.join(curr, ".git")):
            project_dir = curr
            break
        parent = os.path.dirname(curr)
        if parent == curr:
            break
        curr = parent
    if project_dir is None:
        project_dir = os.getcwd()

    if not vault_path:
        vault_root = get_obsidian_vault_root()
        vault_path = os.path.join(vault_root, "INSIGHTS")
    else:
        vault_path = os.path.expanduser(vault_path)
        if os.path.basename(vault_path) != "INSIGHTS":
            vault_path = os.path.join(vault_path, "INSIGHTS")

    if not project_slug:
        project_slug = get_project_slug(project_dir, vault_path)

    if not slug:
        slug = get_active_track_slug()
        
    # Sanitize slug to make it a safe filename (replace non-alphanumeric/non-dash with underscores)
    slug = re.sub(r'[^a-zA-Z0-9_\-]', '_', slug)
    slug = re.sub(r'_+', '_', slug).strip('_')
    if not slug:
        slug = "session_retrospective"
        
    try:
        data = parse_transcript(transcript_path)
    except Exception as e:
        print(f"Error parsing transcript (it might be malformed or incomplete): {e}")
        print("Creating a minimal baseline note so you can fill it manually.")
        data = {
            'overview': 'Agent crashed or transcript was malformed.',
            'total_turns': 0,
            'errors': [{'type': 'ParseError', 'message': str(e)}]
        }
    errors = data.get('errors', [])
    
    today = datetime.now().strftime('%Y-%m-%d')
    filename = f"{today}_{slug}.md"
    target_path = os.path.join(vault_path, filename)
    counter = 1
    while os.path.exists(target_path):
        filename = f"{today}_{slug}_{counter}.md"
        target_path = os.path.join(vault_path, filename)
        counter += 1
    
    os.makedirs(vault_path, exist_ok=True)
    
    # Construct frontmatter
    frontmatter = [
        "---",
        f"title: Session Retrospective: {slug}",
        f"date: {today}",
        "tags:",
        "  - SessionRetro",
        "  - Insights",
        "aliases:",
        f"  - {slug}_retro",
        "---",
        ""
    ]
    
    body = [
        f"# Session Retrospective: {slug}",
        "",
        "## Overview",
        f"This retrospective note documents errors, failed attempts, and successful resolutions during the session working on **{slug}**.",
        ""
    ]
    
    if project_slug:
        # F21 fix: Obsidian resolves wikilinks by note name, not path. Remove folder prefix.
        body.append(f"**Long-Term Memory:** [[{project_slug}|Long-Term Memory Note]]")
        body.append("")
    
    if not errors:
        body.extend([
            "## Outcome",
            "No major errors or tool execution failures were recorded in this session's transcript. All tasks completed smoothly!",
            ""
        ])
    else:
        body.append("## Errors Encountered")
        body.append("")
        for idx, err in enumerate(errors):
            step = err.get('step_index')
            msg = str(err.get('error_message') or '').strip()
            tool_name = err.get('failed_tool_name', 'unknown')
            tool_args = json.dumps(err.get('failed_tool_args', {}), indent=2)
            
            is_sub = err.get('is_subagent', False)
            sub_role = err.get('subagent_role', 'Subagent')
            header_suffix = f" (Subagent: {sub_role})" if is_sub else ""
            
            formatted_msg = '\n'.join([f"  > {line}" for line in msg.split('\n')])
            body.extend([
                f"### {idx + 1}. Error at Step {step}{header_suffix}",
                f"- **Failed Tool:** `{tool_name}`",
                "- **Arguments:**",
                "```json",
                f"{tool_args}",
                "```",
                "- **Error Message:**",
                "  > [!failure]",
                formatted_msg,
                ""
            ])
            
            # Failed attempts
            attempts = err.get('failed_attempts', [])
            if attempts:
                body.append("- **Failed Attempts:**")
                for att in attempts:
                    body.append(f"  - {att.strip()}")
                body.append("")
            
            # Resolution
            res_desc = err.get('resolution', '').strip()
            res_tool = err.get('resolved_tool_name', 'unknown')
            res_args = json.dumps(err.get('resolved_tool_args', {}), indent=2)
            
            body.extend([
                "- **Resolution:**",
                f"  - **Explanation:** {res_desc if res_desc else 'Resolved successfully.'}",
                f"  - **Successful Tool Call:** `{res_tool}`",
                "  ```json",
                f"  {res_args}",
                "  ```",
                ""
            ])
            
    # Reuses resolved project_dir for git history

    # Retrieve git history
    git_history = get_recent_commits(project_dir)
    if git_history:
        body.extend([
            "## Git History",
            git_history,
            ""
        ])

    body.append("**Tags:** #SessionRetro #Insights #LessonsLearned")
    body.append("")
    
    content = "\n".join(frontmatter + body)
    
    with open(target_path, 'w', encoding='utf-8') as f:
        f.write(content)
        
    print(f"Retrospective note successfully written to {target_path}")
    
    # Sync/Open UI if requested
    if open_in_obsidian:
        try:
            vault_root = get_obsidian_vault_root()
            try:
                rel_path = os.path.relpath(target_path, vault_root)
            except ValueError:
                rel_path = f"INSIGHTS/{filename}"
            
            # Obsidian open CLI command expects key=value form for path. Use Popen to run asynchronously.
            subprocess.Popen(["obsidian", "open", f"path={rel_path}"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            print(f"Opened {rel_path} in Obsidian (non-blocking).")
        except (OSError, FileNotFoundError) as e:
            print(f"Warning: Could not open in Obsidian: {e}")
            
    return target_path

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Generate Obsidian Session Retrospective Note")
    parser.add_argument('--transcript', required=True, help="Path to transcript.jsonl")
    parser.add_argument('--vault', help="Path to INSIGHTS folder (defaults to OBSIDIAN_VAULT_ROOT/INSIGHTS)")
    parser.add_argument('--slug', help="Descriptive slug for the note filename")
    # F6 fix: renamed from --open to --open-obsidian to avoid shadowing Python's open() builtin
    parser.add_argument('--open-obsidian', action='store_true', dest='open_obsidian', help="Open the note in Obsidian UI")
    parser.add_argument('--project-slug', help="Optional slug of the long-term memory note for automated cross-linking")
    
    args = parser.parse_args()
    generate_retro_note(args.transcript, args.vault, args.slug, args.open_obsidian, args.project_slug)
