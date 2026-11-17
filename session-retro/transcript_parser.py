import sys
import json
import os
import re
import ast

def name_matches_type(tool_name, step_type):
    if not tool_name or not step_type:
        return False
    t = tool_name.split(':')[-1].lower().replace('_', '').replace('-', '')
    s = step_type.lower().replace('_', '').replace('-', '')
    if t == s:
        return True
    
    # Eager MCP tool matching (e.g. mcp_standard_nushell_evaluate has type MCP_TOOL)
    if t.startswith('mcp') and s == 'mcptool':
        return True
    
    # Explicit equivalence mapping for known mismatches
    equivalences = {
        ('listdir', 'listdirectory'),
        ('listdirectory', 'listdir'),
        ('askuser', 'askquestion'),
        ('askquestion', 'askuser'),
        ('runcommand', 'command'),
        ('command', 'runcommand'),
        ('writetofile', 'writefile'),
        ('writefile', 'writetofile'),
        ('callmcptool', 'mcptool'),
        ('mcptool', 'callmcptool'),
    }
    if (t, s) in equivalences:
        return True
    return False

def get_mcp_details(name, args):
    if not name:
        return None, None
    norm = name.split(':')[-1]
    server, tool = None, None
    if norm == 'call_mcp_tool' and isinstance(args, dict):
        server, tool = args.get('ServerName'), args.get('ToolName')
    elif norm.startswith('mcp_'):
        parts = norm.split('_', 2)
        if len(parts) == 3:
            server, tool = parts[1], parts[2]
            
    if server and isinstance(server, str):
        server = server.strip('"\'').strip()
    if tool and isinstance(tool, str):
        tool = tool.strip('"\'').strip()
    return server, tool

def normalize_path(p):
    if not p or not isinstance(p, str):
        return None
    p = p.strip('"\'').strip()
    if p.startswith('file://'):
        p = p[7:]
    return os.path.abspath(os.path.expanduser(p))

def normalize_command(c):
    if not c or not isinstance(c, str):
        return None
    c = c.strip('"\'').strip()
    return ' '.join(c.split())

def tools_are_equivalent(name_a, args_a, name_b, args_b):
    norm_a = name_a.split(':')[-1] if name_a else ""
    norm_b = name_b.split(':')[-1] if name_b else ""
    
    server_a, tool_a = get_mcp_details(name_a, args_a)
    server_b, tool_b = get_mcp_details(name_b, args_b)
    
    if server_a or server_b:
        if server_a != server_b or tool_a != tool_b or server_a is None:
            return False
        # For standard-nushell evaluate, compare the input Nushell code to avoid false resolutions
        if server_a == 'standard-nushell' and tool_a == 'evaluate':
            code_a = args_a.get('input') if isinstance(args_a, dict) else None
            code_b = args_b.get('input') if isinstance(args_b, dict) else None
            
            # Extract from nested 'Arguments' if using call_mcp_tool format
            if isinstance(args_a, dict) and 'Arguments' in args_a:
                args_a_val = args_a['Arguments']
                if isinstance(args_a_val, str):
                    try:
                        inner = json.loads(args_a_val)
                        code_a = inner.get('input')
                    except Exception:
                        pass
            if isinstance(args_b, dict) and 'Arguments' in args_b:
                args_b_val = args_b['Arguments']
                if isinstance(args_b_val, str):
                    try:
                        inner = json.loads(args_b_val)
                        code_b = inner.get('input')
                    except Exception:
                        pass
            return code_a == code_b and code_a is not None
        return True
        
    if norm_a != norm_b:
        return False
        
    # Check key arguments for native file/command tools to prevent false mapping
    if norm_a in ('write_to_file', 'replace_file_content', 'multi_replace_file_content'):
        file_a = normalize_path(args_a.get('AbsolutePath') or args_a.get('TargetFile')) if isinstance(args_a, dict) else None
        file_b = normalize_path(args_b.get('AbsolutePath') or args_b.get('TargetFile')) if isinstance(args_b, dict) else None
        return file_a == file_b and file_a is not None
        
    if norm_a == 'run_command':
        cmd_a = normalize_command(args_a.get('CommandLine')) if isinstance(args_a, dict) else None
        cmd_b = normalize_command(args_b.get('CommandLine')) if isinstance(args_b, dict) else None
        return cmd_a == cmd_b and cmd_a is not None
        
    return True

def is_diagnostic_tool(name, args):
    norm_name = name.split(':')[-1] if name else ""
    diagnostic_names = {
        'view_file', 'list_dir', 'grep_search', 'search_web', 'read_url_content',
        'read_resource', 'list_resources', 'list_permissions', 'ask_permission',
        'ask_question', 'ask_user', 'manage_task', 'manage_subagents', 'schedule', 'send_message'
    }
    if norm_name in diagnostic_names:
        return True
        
    if norm_name == 'call_mcp_tool' and isinstance(args, dict):
        tool_name = (args.get('ToolName') or '').lower()
        server_name = (args.get('ServerName') or '').lower()
        # Common search/read prefixes
        if any(prefix in tool_name for prefix in ['search', 'get', 'read', 'list', 'query', 'fetch', 'stats', 'doctor']):
            return True
        if server_name in ['standard-ref', 'standard-bravesearch', 'standard-context7', 'standard-deepwiki', 'standard-exa', 'standard-firecrawl']:
            if not any(write_keyword in tool_name for write_keyword in ['write', 'edit', 'update', 'delete', 'create', 'run', 'execute']):
                return True
                
    return False

def _parse_single_transcript(file_path):
    """Parse a single transcript.jsonl file and extract error events with resolution context."""
    steps = []
    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            if line.strip():
                try:
                    steps.append(json.loads(line))
                except json.JSONDecodeError:
                    pass
                
    # 1. Map tool outputs to their planner requests
    tool_executions = []
    pending_calls = []
    
    # We will enrich steps with their corresponding tool call details if they are tool executions
    for step in steps:
        stype = step.get('type')
        if stype == 'PLANNER_RESPONSE':
            # Extract tool calls
            pending_calls = []
            calls = step.get('tool_calls') or []
            for c in calls:
                # Handle cases where args/name might be nested or direct
                name = c.get('name')
                args = c.get('args', {})
                if isinstance(args, str):
                    try:
                        args = json.loads(args)
                    except json.JSONDecodeError:
                        pass
                pending_calls.append({'name': name, 'args': args})
        elif step.get('source') == 'MODEL' and stype != 'PLANNER_RESPONSE':
            match_idx = -1
            for k, call in enumerate(pending_calls):
                if name_matches_type(call['name'], stype):
                    match_idx = k
                    break
            
            if match_idx != -1:
                call = pending_calls.pop(match_idx)
                step['tool_call_name'] = call['name']
                step['tool_call_args'] = call['args']
            elif pending_calls:
                call = pending_calls.pop(0)
                step['tool_call_name'] = call['name']
                step['tool_call_args'] = call['args']
            else:
                step['tool_call_name'] = stype.lower()
                step['tool_call_args'] = {}
                
    # 2. Find errors
    errors = []
    for idx, step in enumerate(steps):
        if step.get('status') == 'ERROR':
            errors.append({
                'error_step_index': idx,
                'step': step
            })
            
    # 3. For each error, find the failed attempts and resolution
    parsed_errors = []
    for err_info in errors:
        err_idx = err_info['error_step_index']
        err_step = err_info['step']
        
        failed_tool_name = err_step.get('tool_call_name', '')
        failed_tool_args = err_step.get('tool_call_args', {})
        failed_attempts = []
        
        # Look forward for resolution step (exact matching or equivalent tool)
        resolution_step = None
        for j in range(err_idx + 1, len(steps)):
            s = steps[j]
            if s.get('status') == 'DONE' and tools_are_equivalent(
                s.get('tool_call_name', ''), s.get('tool_call_args', {}),
                failed_tool_name, failed_tool_args
            ):
                # Found the successful execution of the equivalent tool!
                resolution_step = s
                break
                
        # If no same-tool resolution found, take the first successful tool call
        if not resolution_step:
            is_diag = is_diagnostic_tool(failed_tool_name, failed_tool_args)
            for j in range(err_idx + 1, len(steps)):
                s = steps[j]
                if (s.get('status') == 'DONE' and 
                    s.get('type') not in ['PLANNER_RESPONSE', 'USER_INPUT', 'CONVERSATION_HISTORY']):
                    s_name = s.get('tool_call_name', '')
                    s_args = s.get('tool_call_args', {})
                    if is_diag:
                        # If the failed tool was diagnostic, resolve with the first successful tool of the same type
                        if s_name and failed_tool_name and s_name.split(':')[-1] == failed_tool_name.split(':')[-1]:
                            resolution_step = s
                            break
                    else:
                        # Otherwise, skip diagnostic tools
                        if not is_diagnostic_tool(s_name, s_args):
                            resolution_step = s
                            break
                    
        # Extract resolution details
        resolution_desc = ""
        resolved_tool_name = ""
        resolved_tool_args = {}
        
        if resolution_step:
            res_idx = steps.index(resolution_step)
            resolved_tool_name = resolution_step.get('tool_call_name', '')
            resolved_tool_args = resolution_step.get('tool_call_args', {})
            
            # Look backwards from resolution_step to find its planner response description
            triggering_planner_idx = None
            for k in range(res_idx - 1, err_idx, -1):
                if steps[k].get('type') == 'PLANNER_RESPONSE':
                    resolution_desc = steps[k].get('content', '')
                    triggering_planner_idx = k
                    break
            
            # Collect failed attempts up to the triggering planner response
            limit_idx = triggering_planner_idx if triggering_planner_idx is not None else res_idx
            for j in range(err_idx + 1, limit_idx):
                s = steps[j]
                if s.get('type') == 'PLANNER_RESPONSE':
                    content = s.get('content', '').strip()
                    if content:
                        failed_attempts.append(content)
        else:
            # Collect all planner responses as failed attempts
            for j in range(err_idx + 1, len(steps)):
                s = steps[j]
                if s.get('type') == 'PLANNER_RESPONSE':
                    content = s.get('content', '').strip()
                    if content:
                        failed_attempts.append(content)
                    
        parsed_errors.append({
            'step_index': err_step.get('step_index'),
            'error_message': err_step.get('content', ''),
            'failed_tool_name': failed_tool_name,
            'failed_tool_args': failed_tool_args,
            'failed_attempts': failed_attempts,
            'resolution': resolution_desc,
            'resolved_tool_name': resolved_tool_name,
            'resolved_tool_args': resolved_tool_args,
            'created_at': err_step.get('created_at', '')
        })
        
    return {'errors': parsed_errors}

def find_subagent_ids(file_path, parent_id, brain_dir):
    subagent_ids = set()
    uuid_pattern = re.compile(r'\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b', re.IGNORECASE)
    
    if not os.path.exists(file_path):
        return []
        
    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            for match in uuid_pattern.findall(line):
                match_lower = match.lower()
                if match_lower != parent_id.lower():
                    # Check if the subagent folder exists in brain_dir
                    subagent_dir = os.path.join(brain_dir, match_lower)
                    sub_transcript = os.path.join(subagent_dir, ".system_generated", "logs", "transcript.jsonl")
                    if os.path.exists(sub_transcript):
                        subagent_ids.add(match_lower)
                        
    return list(subagent_ids)

def get_all_transcripts(main_file_path):
    transcripts = {}
    
    main_file_path = os.path.abspath(main_file_path)
    parent_dir = os.path.dirname(os.path.dirname(os.path.dirname(main_file_path)))
    
    # Safety check: if not in standard brain/.system_generated/logs/ structure, return just main
    if os.path.basename(os.path.dirname(os.path.dirname(main_file_path))) != '.system_generated':
        return {os.path.basename(main_file_path): main_file_path}
        
    parent_id = os.path.basename(parent_dir)
    brain_dir = os.path.dirname(parent_dir)
    
    transcripts[parent_id] = main_file_path
    
    queue = [parent_id]
    visited = {parent_id}
    
    while queue:
        curr_id = queue.pop(0)
        curr_file = transcripts[curr_id]
        
        sub_ids = find_subagent_ids(curr_file, curr_id, brain_dir)
        for sid in sub_ids:
            if sid not in visited:
                visited.add(sid)
                sub_file = os.path.join(brain_dir, sid, ".system_generated", "logs", "transcript.jsonl")
                transcripts[sid] = sub_file
                queue.append(sid)
                
    return transcripts

def get_case_insensitive_key(d, key_to_find):
    if not isinstance(d, dict):
        return None
    # Normalize key_to_find to lowercase and remove spaces, dashes, underscores
    norm_find = key_to_find.lower().replace('_', '').replace('-', '')
    for k, v in d.items():
        norm_k = str(k).lower().replace('_', '').replace('-', '')
        if norm_k == norm_find:
            return v
    return None

def extract_subagent_roles(transcripts):
    roles = {}
    for conv_id, path in transcripts.items():
        if not os.path.exists(path):
            continue
            
        steps = []
        with open(path, 'r', encoding='utf-8') as f:
            for line in f:
                if line.strip():
                    try:
                        steps.append(json.loads(line))
                    except Exception:
                        pass
                        
        # Map tool outputs to their planner requests to enrich steps
        pending_calls = []
        for step in steps:
            stype = step.get('type')
            if stype == 'PLANNER_RESPONSE':
                pending_calls = []
                calls = step.get('tool_calls', [])
                for c in calls:
                    name = c.get('name')
                    args = c.get('args', {})
                    if isinstance(args, str):
                        try:
                            args = json.loads(args)
                        except json.JSONDecodeError:
                            pass
                    pending_calls.append({'name': name, 'args': args})
            elif step.get('source') == 'MODEL' and stype != 'PLANNER_RESPONSE':
                match_idx = -1
                for k, call in enumerate(pending_calls):
                    if name_matches_type(call['name'], stype):
                        match_idx = k
                        break
                if match_idx != -1:
                    call = pending_calls.pop(match_idx)
                    step['tool_call_name'] = call['name']
                    step['tool_call_args'] = call['args']
                elif pending_calls:
                    call = pending_calls.pop(0)
                    step['tool_call_name'] = call['name']
                    step['tool_call_args'] = call['args']
                else:
                    step['tool_call_name'] = stype.lower()
                    step['tool_call_args'] = {}
                    
        last_invoked_subagents = []
        
        for step in steps:
            stype = step.get('type')
            if stype == 'PLANNER_RESPONSE':
                for c in (step.get('tool_calls') or []):
                    name = c.get('name', '')
                    if name and name.split(':')[-1] in ('invoke_agent', 'invoke_subagent'):
                        args = c.get('args', {})
                        if isinstance(args, str):
                            try:
                                args = json.loads(args)
                            except Exception:
                                pass
                        
                        subagents = args.get('Subagents', [])
                        if isinstance(subagents, list) and subagents:
                            last_invoked_subagents = []
                            for sub in subagents:
                                if isinstance(sub, dict):
                                    role = sub.get('Role') or sub.get('TypeName') or 'Subagent'
                                    last_invoked_subagents.append(role)
                        else:
                            agent_name = args.get('agent_name', '')
                            if agent_name:
                                last_invoked_subagents = [agent_name]
                            else:
                                last_invoked_subagents = ['Subagent']
                                
            elif step.get('source') == 'MODEL' and stype != 'PLANNER_RESPONSE':
                tool_name = step.get('tool_call_name', '')
                if tool_name and tool_name.split(':')[-1] in ('invoke_agent', 'invoke_subagent'):
                    content = step.get('content', '')
                    if content:
                        data = None
                        try:
                            data = json.loads(content)
                        except Exception:
                            try:
                                data = ast.literal_eval(content)
                            except Exception:
                                pass
                        
                        if isinstance(data, list):
                            for idx, item in enumerate(data):
                                if isinstance(item, dict):
                                    cid = get_case_insensitive_key(item, 'conversationID')
                                    if cid:
                                        role = item.get('Role') or item.get('TypeName')
                                        if not role and idx < len(last_invoked_subagents):
                                            role = last_invoked_subagents[idx]
                                        if not role:
                                            role = 'Subagent'
                                        roles[str(cid).lower()] = role
                        elif isinstance(data, dict):
                            cid = get_case_insensitive_key(data, 'conversationID')
                            if cid:
                                role = data.get('Role') or data.get('TypeName')
                                if not role and last_invoked_subagents:
                                    role = last_invoked_subagents[0]
                                if not role:
                                    role = 'Subagent'
                                roles[str(cid).lower()] = role
    return roles

def parse_transcript(file_path):
    """Parse transcript and all associated subagent transcripts, returning combined sorted errors."""
    transcripts = get_all_transcripts(file_path)
    main_id = list(transcripts.keys())[0]
    roles = extract_subagent_roles(transcripts)
    
    all_errors = []
    for conv_id, path in transcripts.items():
        res = _parse_single_transcript(path)
        errors = res.get('errors', [])
        for err in errors:
            if conv_id != main_id:
                err['is_subagent'] = True
                err['subagent_id'] = conv_id
                err['subagent_role'] = roles.get(conv_id.lower(), "Subagent")
            else:
                err['is_subagent'] = False
            all_errors.append(err)
            
    # Sort errors chronologically by timestamp
    all_errors.sort(key=lambda x: x.get('created_at', ''))
    return {'errors': all_errors}

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: parser.py <path_to_transcript_jsonl>")
        sys.exit(1)
    res = parse_transcript(sys.argv[1])
    print(json.dumps(res, indent=2))
