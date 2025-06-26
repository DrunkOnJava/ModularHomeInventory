# GitHub Secrets Configuration for TestFlight Deployment

To enable automated TestFlight uploads via GitHub Actions, you need to configure the following secrets in your GitHub repository settings:

## Required Secrets

### 1. Code Signing Certificate
- **Secret Name**: `CERTIFICATE_BASE64`
- **How to Get**: 
  ```bash
  # Export your Apple Distribution certificate from Keychain
  # Then convert to base64:
  base64 -i certificate.p12
  ```

### 2. Certificate Password
- **Secret Name**: `CERTIFICATE_PASSWORD`
- **Value**: The password you set when exporting the certificate

### 3. Provisioning Profile
- **Secret Name**: `PROVISIONING_PROFILE_BASE64`
- **How to Get**:
  ```bash
  # Download from Apple Developer Portal, then:
  base64 -i "Home_Inventory_App_Store.mobileprovision"
  ```

### 4. Keychain Password
- **Secret Name**: `KEYCHAIN_PASSWORD`
- **Value**: Any secure password (used for temporary keychain)

### 5. App Store Connect API Keys
- **Secret Name**: `APP_STORE_CONNECT_API_KEY_ID`
- **How to Get**: Create in App Store Connect → Users and Access → Keys

- **Secret Name**: `APP_STORE_CONNECT_ISSUER_ID`
- **How to Get**: Found in App Store Connect → Users and Access → Keys

- **Secret Name**: `APP_STORE_CONNECT_API_KEY_BASE64`
- **How to Get**:
  ```bash
  # Download the .p8 file from App Store Connect, then:
  base64 -i AuthKey_XXXXXXXXXX.p8
  ```

## Setting Secrets in GitHub

1. Go to your repository on GitHub
2. Click Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Add each secret with the exact names above

## Alternative: Using Fastlane Match

If you use Fastlane Match for certificate management, you can simplify this by adding:
- `MATCH_PASSWORD`
- `MATCH_GIT_BASIC_AUTHORIZATION` (base64 encoded "username:personal_access_token")

## Triggering the Workflow

Once all secrets are configured:
```bash
# Push to main branch
git push origin main

# Or trigger manually
gh workflow run testflight.yml
```