#!/usr/bin/osascript

on run
    tell application "iTerm"
        tell current session of current window
            -- Download Swift 5.9
            write text "echo '📥 Downloading Swift 5.9...'"
            write text "cd ~/Downloads"
            write text "curl -L -o swift-5.9-RELEASE-osx.pkg https://download.swift.org/swift-5.9-release/xcode/swift-5.9-RELEASE/swift-5.9-RELEASE-osx.pkg"
            
            -- Show download progress
            write text "echo ''"
            write text "echo '📦 Download complete! Installing Swift 5.9...'"
            write text "echo 'This will require your admin password.'"
            write text "echo ''"
            
            -- Install the package
            write text "sudo installer -pkg swift-5.9-RELEASE-osx.pkg -target /"
            
            -- After installation, go back and run setup
            write text "echo ''"
            write text "echo '✅ Swift 5.9 installed! Running setup...'"
            write text "cd /Users/griffin/Projects/ModularHomeInventory"
            write text "./setup_swift_5.9.sh"
        end tell
    end tell
end run