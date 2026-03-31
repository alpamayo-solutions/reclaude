function _reclaude_launch --description "Launch Claude: resume existing or start named session"
    set -l name $argv[1]

    # Check if a session with this name already exists before attempting resume.
    # claude --resume opens an interactive picker when no match exists,
    # so we avoid calling it unless we know the session is there.
    set -l has_session (python3 -c '
import json, glob, os, sys
name = sys.argv[1]
for f in glob.glob(os.path.expanduser("~/.claude/sessions/*.json")):
    try:
        with open(f) as fh:
            if json.load(fh).get("name") == name:
                print("yes")
                sys.exit()
    except Exception:
        pass
print("no")
' "$name" 2>/dev/null)

    if test "$has_session" = "yes"
        claude --resume "$name"
    else
        claude --name "$name"
    end
end
