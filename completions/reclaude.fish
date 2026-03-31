# Completions for reclaude

# Disable file completions by default
complete -c reclaude -f

# Subcommands (only when no subcommand given yet)
complete -c reclaude -n "not __fish_seen_subcommand_from new open save list ls remove rm help" -a new -d "Create session profile and open in new tab"
complete -c reclaude -n "not __fish_seen_subcommand_from new open save list ls remove rm help" -a open -d "Open existing session in new tab or split"
complete -c reclaude -n "not __fish_seen_subcommand_from new open save list ls remove rm help" -a save -d "Save current window arrangement as default"
complete -c reclaude -n "not __fish_seen_subcommand_from new open save list ls remove rm help" -a list -d "List all session profiles"
complete -c reclaude -n "not __fish_seen_subcommand_from new open save list ls remove rm help" -a remove -d "Remove a session profile"
complete -c reclaude -n "not __fish_seen_subcommand_from new open save list ls remove rm help" -a help -d "Show help"

# new --dir
complete -c reclaude -n "__fish_seen_subcommand_from new" -l dir -s d -r -F -d "Working directory for the session"

# open --split
complete -c reclaude -n "__fish_seen_subcommand_from open" -l split -s s -x -a "h v" -d "Split direction (h=horizontal, v=vertical)"

# Session name completions for open and remove (read from profiles JSON)
function __reclaude_session_names
    set -l file "$HOME/Library/Application Support/iTerm2/DynamicProfiles/claude-sessions.json"
    if test -f "$file"
        python3 -c '
import json, os, sys
try:
    with open(os.environ["CSESSION_FILE"]) as f:
        for p in json.load(f).get("Profiles", []):
            print(p["Name"].replace("claude: ", ""))
except Exception:
    pass
' CSESSION_FILE="$file" 2>/dev/null
    end
end

complete -c reclaude -n "__fish_seen_subcommand_from open" -a "(__reclaude_session_names)" -d "Session name"
complete -c reclaude -n "__fish_seen_subcommand_from remove rm" -a "(__reclaude_session_names)" -d "Session name"
