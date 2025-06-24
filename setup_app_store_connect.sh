#!/bin/bash

echo "🔐 Setting up App Store Connect credentials for Fastlane"
echo ""
echo "You need to create an app-specific password at: https://appleid.apple.com"
echo "Once you have it, run this command:"
echo ""
echo "export FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD='your-app-specific-password'"
echo ""
echo "Or add it to your ~/.zshrc or ~/.bash_profile:"
echo "echo 'export FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD=\"your-app-specific-password\"' >> ~/.zshrc"
echo ""
echo "Then run: bundle exec fastlane testflight force:true"