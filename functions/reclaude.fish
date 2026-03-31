function reclaude --description "Pin Claude Code sessions to iTerm2 panes"
    if test (count $argv) -eq 0
        _reclaude_help
        return 1
    end

    switch $argv[1]
        case new
            set -e argv[1]
            _reclaude_new $argv
        case open
            set -e argv[1]
            _reclaude_open $argv
        case list ls
            _reclaude_list
        case save
            _reclaude_save
        case remove rm
            set -e argv[1]
            _reclaude_remove $argv
        case help -h --help
            _reclaude_help
        case '*'
            echo "reclaude: unknown command '$argv[1]'"
            return 1
    end
end

function _reclaude_help
    echo "reclaude - Pin Claude Code sessions to iTerm2 panes"
    echo ""
    echo "Usage: reclaude <command> [args]"
    echo ""
    echo "Commands:"
    echo "  new <name> [--dir <path>]    Create session profile and open in new tab"
    echo "  open <name> [--split h|v]    Open existing session in new tab or split"
    echo "  save                         Save current window arrangement as default"
    echo "  list                         List all session profiles"
    echo "  remove <name>                Remove a session profile"
    echo "  help                         Show this help"
    echo ""
    echo "Setup:"
    echo ""
    echo "  1. Create sessions:"
    echo "       reclaude new prekit-api --dir ~/Projects/prekit/api"
    echo "       reclaude new chocolate --dir ~/Projects/prekit"
    echo ""
    echo "  2. Arrange splits in iTerm2:"
    echo "       Cmd+D          split vertically (side by side)"
    echo "       Cmd+Shift+D    split horizontally (top/bottom)"
    echo "       Or: reclaude open <name> --split h|v"
    echo ""
    echo "  3. Save the arrangement:"
    echo "       reclaude save"
    echo ""
    echo "  4. Set auto-restore on launch:"
    echo "       iTerm2 > Settings > General > Startup"
    echo "       Set to 'Open Default Window Arrangement'"
    echo ""
    echo "  After a reboot, iTerm2 restores the layout and each pane"
    echo "  resumes its Claude session automatically."
end

function _reclaude_profiles_file
    echo "$HOME/Library/Application Support/iTerm2/DynamicProfiles/claude-sessions.json"
end

function _reclaude_ensure_file
    set -l dir "$HOME/Library/Application Support/iTerm2/DynamicProfiles"
    set -l file "$dir/claude-sessions.json"
    mkdir -p "$dir"
    if not test -f "$file"
        echo '{"Profiles": []}' >"$file"
    end
end

function _reclaude_new
    set -l name ""
    set -l dir (pwd)

    # Parse arguments
    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case --dir -d
                set i (math $i + 1)
                if test $i -gt (count $argv)
                    echo "reclaude new: --dir requires a path"
                    return 1
                end
                set dir $argv[$i]
            case '--*'
                echo "reclaude new: unknown option $argv[$i]"
                return 1
            case '*'
                if test -z "$name"
                    set name $argv[$i]
                else
                    echo "reclaude new: unexpected argument '$argv[$i]'"
                    return 1
                end
        end
        set i (math $i + 1)
    end

    if test -z "$name"
        echo "Usage: reclaude new <name> [--dir <path>]"
        return 1
    end

    # Resolve to absolute path
    set dir (realpath "$dir" 2>/dev/null; or echo "$dir")
    if not test -d "$dir"
        echo "reclaude new: directory does not exist: $dir"
        return 1
    end

    _reclaude_ensure_file
    set -l file (_reclaude_profiles_file)

    # Check for duplicates and add profile
    set -l guid (uuidgen)
    set -l result (
        CSESSION_FILE="$file" \
        CSESSION_NAME="$name" \
        CSESSION_DIR="$dir" \
        CSESSION_GUID="$guid" \
        python3 -c '
import json, os, sys

file = os.environ["CSESSION_FILE"]
name = os.environ["CSESSION_NAME"]
wdir = os.environ["CSESSION_DIR"]
guid = os.environ["CSESSION_GUID"]
profile_name = f"claude: {name}"

with open(file) as f:
    data = json.load(f)

for p in data["Profiles"]:
    if p.get("Name") == profile_name:
        print("exists")
        sys.exit()

data["Profiles"].append({
    "Name": profile_name,
    "Guid": guid,
    "Dynamic Profile Parent Name": "Default",
    "Custom Directory": "Yes",
    "Working Directory": wdir,
    "Initial Text": f"_reclaude_launch {name}",
    "Tags": ["claude-session"],
})

with open(file, "w") as f:
    json.dump(data, f, indent=2)
print("ok")
'
    )

    if test "$result" = "exists"
        echo "Session '$name' already exists. Use 'reclaude open $name' instead."
        return 1
    end

    echo "Created session '$name' (dir: $dir)"
    _reclaude_iterm_open "claude: $name"
end

function _reclaude_open
    set -l name ""
    set -l split ""

    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case --split -s
                set i (math $i + 1)
                if test $i -gt (count $argv)
                    echo "reclaude open: --split requires h or v"
                    return 1
                end
                set split $argv[$i]
            case '--*'
                echo "reclaude open: unknown option $argv[$i]"
                return 1
            case '*'
                if test -z "$name"
                    set name $argv[$i]
                end
        end
        set i (math $i + 1)
    end

    if test -z "$name"
        echo "Usage: reclaude open <name> [--split h|v]"
        return 1
    end

    # Verify the profile exists
    _reclaude_ensure_file
    set -l file (_reclaude_profiles_file)
    set -l found (
        CSESSION_FILE="$file" CSESSION_NAME="$name" python3 -c '
import json, os
with open(os.environ["CSESSION_FILE"]) as f:
    data = json.load(f)
target = f"claude: {os.environ["CSESSION_NAME"]}"
print("yes" if any(p["Name"] == target for p in data["Profiles"]) else "no")
'
    )

    if test "$found" != "yes"
        echo "Session '$name' not found. Run 'reclaude list' to see available sessions."
        return 1
    end

    set -l profile_name "claude: $name"

    switch "$split"
        case h horizontal
            _reclaude_iterm_split "$profile_name" horizontally
        case v vertical
            _reclaude_iterm_split "$profile_name" vertically
        case ""
            _reclaude_iterm_open "$profile_name"
        case '*'
            echo "reclaude open: --split must be 'h' or 'v'"
            return 1
    end
end

function _reclaude_iterm_open
    set -l profile $argv[1]
    osascript -e "
        tell application \"iTerm2\"
            tell current window
                create tab with profile \"$profile\"
            end tell
            activate
        end tell
    " 2>/dev/null
    or osascript -e "
        tell application \"iTerm2\"
            create window with profile \"$profile\"
            activate
        end tell
    " 2>/dev/null
    or echo "Failed to open tab. Is iTerm2 running?"
end

function _reclaude_iterm_split
    set -l profile $argv[1]
    set -l direction $argv[2]
    osascript -e "
        tell application \"iTerm2\"
            tell current session of current window
                split $direction with profile \"$profile\"
            end tell
            activate
        end tell
    " 2>/dev/null
    or echo "Failed to split pane. Is iTerm2 running with a window open?"
end

function _reclaude_save
    echo "Saving current window arrangement as default..."
    osascript -e '
        tell application "System Events"
            tell process "iTerm2"
                set frontmost to true
                click menu item "Save Current Window Arrangement as Default" of menu "Window" of menu bar 1
            end tell
        end tell
    ' 2>/dev/null
    and echo "Default window arrangement saved."
    or begin
        echo "Failed to save arrangement."
        echo "Make sure iTerm2 is running and Accessibility permissions are granted."
        echo "  System Settings > Privacy & Security > Accessibility > enable iTerm2"
        return 1
    end
end

function _reclaude_list
    _reclaude_ensure_file
    set -l file (_reclaude_profiles_file)

    CSESSION_FILE="$file" python3 -c '
import json, os

with open(os.environ["CSESSION_FILE"]) as f:
    data = json.load(f)

profiles = data.get("Profiles", [])
if not profiles:
    print("No Claude sessions configured.")
    print("Run: reclaude new <name> [--dir <path>]")
else:
    col1 = "Name"
    col2 = "Directory"
    sep = chr(9472)
    print(f"  {col1:<25} {col2}")
    print(f"  {sep * 25} {sep * 50}")
    for p in profiles:
        name = p["Name"].replace("claude: ", "")
        wdir = p.get("Working Directory", "?")
        home = os.path.expanduser("~")
        if wdir.startswith(home):
            wdir = "~" + wdir[len(home):]
        print(f"  {name:<25} {wdir}")
    print(f"\n  {len(profiles)} session(s)")
'
end

function _reclaude_remove
    if test (count $argv) -eq 0
        echo "Usage: reclaude remove <name>"
        return 1
    end

    _reclaude_ensure_file
    set -l file (_reclaude_profiles_file)
    set -l name $argv[1]

    set -l result (
        CSESSION_FILE="$file" CSESSION_NAME="$name" python3 -c '
import json, os

file = os.environ["CSESSION_FILE"]
name = os.environ["CSESSION_NAME"]
target = f"claude: {name}"

with open(file) as f:
    data = json.load(f)

before = len(data["Profiles"])
data["Profiles"] = [p for p in data["Profiles"] if p.get("Name") != target]
after = len(data["Profiles"])

with open(file, "w") as f:
    json.dump(data, f, indent=2)

print("yes" if before > after else "no")
'
    )

    if test "$result" = "yes"
        echo "Removed session '$name'"
    else
        echo "Session '$name' not found"
        return 1
    end
end
