#!/usr/bin/osascript

tell application "iTerm"
    activate
    
    -- Create a new window
    set newWindow to (create window with default profile)
    
    -- Wait a moment for the window to be ready
    delay 1
    
    -- Get the current session of the new window
    tell current session of newWindow
        -- Send the command to download and install Swift 5.9
        write text "cd ~/Downloads && curl -L -o swift-5.9-RELEASE-osx.pkg https://download.swift.org/swift-5.9-release/xcode/swift-5.9-RELEASE/swift-5.9-RELEASE-osx.pkg && echo '📦 Installing Swift 5.9 (password required)...' && sudo installer -pkg swift-5.9-RELEASE-osx.pkg -target / && cd /Users/griffin/Projects/ModularHomeInventory && ./setup_swift_5.9.sh"
    end tell
end tell