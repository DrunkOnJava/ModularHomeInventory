#!/usr/bin/osascript

on run
    tell application "iTerm"
        activate
        
        -- Create new window
        create window with default profile
        
        -- Get the current session
        tell current session of current window
            -- Change to project directory
            write text "cd /Users/griffin/Projects/ModularHomeInventory"
            
            -- Run the setup script
            write text "./setup_swift_5.9.sh"
        end tell
    end tell
end run