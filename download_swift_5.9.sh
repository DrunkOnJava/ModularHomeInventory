#\!/bin/bash
echo "📥 Downloading Swift 5.9..."
cd ~/Downloads
curl -L -o swift-5.9-RELEASE-osx.pkg https://download.swift.org/swift-5.9-release/xcode/swift-5.9-RELEASE/swift-5.9-RELEASE-osx.pkg
echo ""
echo "📦 Download complete\! Installing Swift 5.9..."
echo "This will require your admin password."
echo ""
sudo installer -pkg swift-5.9-RELEASE-osx.pkg -target /
echo ""
echo "✅ Swift 5.9 installed\! Running setup..."
cd /Users/griffin/Projects/ModularHomeInventory
./setup_swift_5.9.sh
