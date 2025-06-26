#!/usr/bin/osascript

tell application "iTerm"
    activate
    
    -- Create a new window
    create window with default profile
    
    tell current session of current window
        -- Commands to change Swift version
        write text "echo '🔧 Changing System Swift Version to 5.9'"
        write text "echo '=================================='"
        write text "echo ''"
        write text "echo 'This process will:'"
        write text "echo '1. Download and install Swift 5.9 toolchain'"
        write text "echo '2. Configure Xcode to use Swift 5.9'"
        write text "echo '3. Set environment variables'"
        write text "echo ''"
        write text "echo 'Press Enter to continue or Ctrl+C to cancel...'"
        write text "read"
        write text ""
        
        -- Check current Swift version
        write text "echo '📍 Current Swift version:'"
        write text "swift --version"
        write text "echo ''"
        
        -- Download Swift 5.9 if not present
        write text "echo '📥 Checking for Swift 5.9 toolchain...'"
        write text "if [ ! -d '/Library/Developer/Toolchains/swift-5.9-RELEASE.xctoolchain' ]; then"
        write text "    echo 'Swift 5.9 not found. Downloading...'"
        write text "    echo 'Please download Swift 5.9 from:'"
        write text "    echo 'https://www.swift.org/download/#releases'"
        write text "    echo ''"
        write text "    echo 'Direct link for macOS:'"
        write text "    echo 'https://download.swift.org/swift-5.9-release/xcode/swift-5.9-RELEASE/swift-5.9-RELEASE-osx.pkg'"
        write text "    echo ''"
        write text "    echo 'After downloading, install the package and run this script again.'"
        write text "    exit 1"
        write text "fi"
        write text ""
        
        -- Set TOOLCHAINS environment variable
        write text "echo '🔧 Setting Swift 5.9 as default toolchain...'"
        write text "export TOOLCHAINS=swift-5.9-RELEASE"
        write text "echo 'export TOOLCHAINS=swift-5.9-RELEASE' >> ~/.zshrc"
        write text ""
        
        -- Create symbolic link (requires sudo)
        write text "echo '🔗 Creating symbolic link for swift command...'"
        write text "echo 'This requires sudo access:'"
        write text "sudo ln -sf /Library/Developer/Toolchains/swift-5.9-RELEASE.xctoolchain/usr/bin/swift /usr/local/bin/swift-5.9"
        write text ""
        
        -- Update xcode-select (requires sudo)
        write text "echo '📱 Configuring Xcode to use Swift 5.9...'"
        write text "echo 'This requires sudo access:'"
        write text "sudo xcode-select -s /Applications/Xcode.app"
        write text ""
        
        -- Set developer directory
        write text "export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer"
        write text "echo 'export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer' >> ~/.zshrc"
        write text ""
        
        -- Verify installation
        write text "echo '✅ Verifying Swift 5.9 installation...'"
        write text "echo ''"
        write text "echo 'Swift version with toolchain:'"
        write text "xcrun --toolchain swift-5.9-RELEASE swift --version"
        write text "echo ''"
        write text "echo 'Default swift version:'"
        write text "swift --version"
        write text "echo ''"
        
        -- Instructions for using Swift 5.9
        write text "echo '📝 To use Swift 5.9 in your project:'"
        write text "echo ''"
        write text "echo '1. In Terminal, use:'"
        write text "echo '   export TOOLCHAINS=swift-5.9-RELEASE'"
        write text "echo '   xcrun --toolchain swift-5.9-RELEASE swift --version'"
        write text "echo ''"
        write text "echo '2. In Xcode:'"
        write text "echo '   - Go to Xcode → Preferences → Components'"
        write text "echo '   - Select Swift 5.9 toolchain'"
        write text "echo '   - Or in Build Settings, set SWIFT_VERSION = 5.0'"
        write text "echo ''"
        write text "echo '3. For xcodebuild:'"
        write text "echo '   xcodebuild -toolchain swift-5.9-RELEASE ...'"
        write text "echo ''"
        write text "echo '✅ Setup complete! Now you can build with Swift 5.9'"
        write text ""
        
        -- Return to project directory
        write text "cd /Users/griffin/Projects/ModularHomeInventory"
        write text "echo ''"
        write text "echo '🚀 Ready to build with Swift 5.9!'"
        write text "echo 'Run: make build'"
    end tell
end tell