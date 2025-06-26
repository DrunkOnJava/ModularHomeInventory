#!/usr/bin/env python3

import iterm2
import asyncio

async def main(connection):
    # Get the current app
    app = await iterm2.async_get_app(connection)
    
    # Get current window or create new one
    window = app.current_window
    if window is None:
        window = await app.async_create_window()
    
    # Get current tab
    tab = window.current_tab
    session = tab.current_session
    
    # Commands to run
    commands = [
        "cd /Users/griffin/Projects/ModularHomeInventory",
        "echo '📥 Downloading Swift 5.9...'",
        "cd ~/Downloads",
        "curl -L -o swift-5.9-RELEASE-osx.pkg https://download.swift.org/swift-5.9-release/xcode/swift-5.9-RELEASE/swift-5.9-RELEASE-osx.pkg",
        "echo ''",
        "echo '📦 Download complete! Installing Swift 5.9...'",
        "echo 'This will require your admin password.'",
        "echo ''",
        "sudo installer -pkg swift-5.9-RELEASE-osx.pkg -target /",
        "echo ''",
        "echo '✅ Swift 5.9 installed! Running setup...'",
        "cd /Users/griffin/Projects/ModularHomeInventory",
        "./setup_swift_5.9.sh"
    ]
    
    # Send commands
    for cmd in commands:
        await session.async_send_text(cmd + "\n")
        await asyncio.sleep(0.1)  # Small delay between commands

# Run the script
iterm2.run_until_complete(main)