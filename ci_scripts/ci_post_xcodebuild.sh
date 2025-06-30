#!/bin/sh
# Xcode Cloud Post-Build Script
# This runs after xcodebuild

set -e

echo "🏁 Starting post-build tasks..."

# Check if build succeeded
if [ "$CI_XCODEBUILD_EXIT_CODE" != "0" ]; then
    echo "❌ Build failed with exit code: $CI_XCODEBUILD_EXIT_CODE"
    exit 0  # Don't fail the workflow, just skip post-build
fi

# Generate test report if tests were run
if [ -d "$CI_RESULT_BUNDLE_PATH" ]; then
    echo "📊 Generating test report..."
    # Install xchtmlreport if not available
    if ! command -v xchtmlreport &> /dev/null; then
        brew install xchtmlreport
    fi
    
    # Generate HTML report
    xchtmlreport -r "$CI_RESULT_BUNDLE_PATH" -o TestResults/ || true
    
    # Extract test summary
    if [ -f "TestResults/index.html" ]; then
        echo "✅ Test report generated successfully"
    fi
fi

# Upload dSYMs for crash reporting
if [ -d "$CI_ARCHIVE_PATH" ]; then
    echo "📤 Processing archive at: $CI_ARCHIVE_PATH"
    
    # Find dSYMs
    DSYM_PATH="$CI_ARCHIVE_PATH/dSYMs"
    if [ -d "$DSYM_PATH" ]; then
        echo "📊 Found dSYMs at: $DSYM_PATH"
        
        # Upload to Sentry (if configured)
        if [ -n "$SENTRY_AUTH_TOKEN" ] && [ -n "$SENTRY_ORG" ] && [ -n "$SENTRY_PROJECT" ]; then
            echo "📤 Uploading dSYMs to Sentry..."
            if ! command -v sentry-cli &> /dev/null; then
                curl -sL https://sentry.io/get-cli/ | bash
            fi
            sentry-cli upload-dif "$DSYM_PATH" || true
        fi
        
        # Upload to Firebase Crashlytics (if configured)
        if [ -n "$FIREBASE_TOKEN" ]; then
            echo "📤 Uploading dSYMs to Firebase..."
            # Firebase upload command here
        fi
    fi
fi

# Generate build artifacts summary
echo "📋 Build Summary:"
echo "  Product: $CI_PRODUCT"
echo "  Build: $CI_BUILD_NUMBER"
echo "  Branch: $CI_BRANCH"
if [ -n "$CI_PULL_REQUEST_NUMBER" ]; then
    echo "  PR: #$CI_PULL_REQUEST_NUMBER"
fi

# Create artifacts directory
ARTIFACTS_DIR="BuildArtifacts"
mkdir -p "$ARTIFACTS_DIR"

# Copy important files to artifacts
if [ -f "swiftlint_report.json" ]; then
    cp swiftlint_report.json "$ARTIFACTS_DIR/"
fi

if [ -d "TestResults" ]; then
    cp -r TestResults "$ARTIFACTS_DIR/"
fi

# Generate build info JSON
cat > "$ARTIFACTS_DIR/build_info.json" <<EOF
{
  "build_number": "$CI_BUILD_NUMBER",
  "product": "$CI_PRODUCT",
  "branch": "$CI_BRANCH",
  "commit": "$CI_COMMIT",
  "workflow": "$CI_WORKFLOW",
  "xcode_version": "$CI_XCODE_VERSION",
  "date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

# Run Danger for PR builds (if configured)
if [ -n "$CI_PULL_REQUEST_NUMBER" ] && [ -f "Dangerfile.swift" ]; then
    echo "🤖 Running Danger..."
    if [ -n "$DANGER_GITHUB_API_TOKEN" ]; then
        bundle exec danger || true
    else
        echo "⚠️  DANGER_GITHUB_API_TOKEN not set, skipping Danger"
    fi
fi

# Notify success (customize based on your needs)
echo "🎉 Post-build tasks complete!"

# Optional: Send notifications
if [ -n "$SLACK_WEBHOOK_URL" ]; then
    echo "📢 Sending Slack notification..."
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"✅ Build #$CI_BUILD_NUMBER succeeded for $CI_PRODUCT on branch $CI_BRANCH\"}" \
        "$SLACK_WEBHOOK_URL" || true
fi