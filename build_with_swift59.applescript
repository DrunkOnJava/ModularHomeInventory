#!/usr/bin/osascript

tell application "iTerm"
    tell current session of current window
        -- Export toolchain and build
        write text "export TOOLCHAINS=swift-5.9-RELEASE"
        write text "echo 'Testing Swift 5.9 is active...'"
        write text "xcrun --toolchain swift-5.9-RELEASE swift --version"
        write text "echo ''"
        write text "echo 'Building with Swift 5.9...'"
        write text "cd /Users/griffin/Projects/ModularHomeInventory"
        write text "xcodebuild -toolchain swift-5.9-RELEASE -project HomeInventoryModular.xcodeproj -scheme HomeInventoryModular -configuration Release -destination 'generic/platform=iOS' -derivedDataPath build/DerivedData CODE_SIGN_IDENTITY='Apple Development' DEVELOPMENT_TEAM='2VXBQV4XC9' -allowProvisioningUpdates clean build archive -archivePath build/HomeInventory.xcarchive"
    end tell
end tell