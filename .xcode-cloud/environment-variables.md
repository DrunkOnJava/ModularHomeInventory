# Xcode Cloud Environment Variables

Add these environment variables in your Xcode Cloud workflow configuration:

## Required Variables

### Code Signing (if using Match)
- `MATCH_PASSWORD` - Password for Match repository
- `MATCH_GIT_BASIC_AUTHORIZATION` - Base64 encoded "username:token"

### Apple Developer
- `FASTLANE_USER` - Apple ID email
- `FASTLANE_PASSWORD` - App-specific password
- `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` - For 2FA accounts

## Optional Variables

### Third-Party Services
- `SENTRY_AUTH_TOKEN` - For uploading dSYMs to Sentry
- `SENTRY_ORG` - Sentry organization slug
- `SENTRY_PROJECT` - Sentry project slug
- `FIREBASE_TOKEN` - For Firebase Crashlytics
- `MIXPANEL_TOKEN` - Analytics token
- `REVENUECAT_API_KEY` - RevenueCat API key

### Notifications
- `SLACK_WEBHOOK_URL` - For build notifications
- `DANGER_GITHUB_API_TOKEN` - For PR automation

### Build Configuration
- `SKIP_SWIFTLINT` - Set to "true" to skip linting
- `SKIP_TESTS` - Set to "true" to skip tests
- `ENABLE_BITCODE` - Set to "NO" for faster builds

## Setting Environment Variables

1. In Xcode, go to Product → Xcode Cloud → Manage Workflows
2. Select your workflow
3. Click Edit Workflow
4. Go to Environment tab
5. Add variables as needed

## Security Notes

- Mark sensitive variables as "Secret"
- Never commit these values to your repository
- Use Xcode Cloud's secret management
- Rotate tokens regularly