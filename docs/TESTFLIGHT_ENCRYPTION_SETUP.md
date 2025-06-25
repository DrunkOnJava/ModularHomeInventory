# TestFlight Encryption Compliance Setup Guide

## Overview
This guide explains how to properly configure encryption compliance for TestFlight and App Store distribution, particularly for France's requirements.

## Step 1: Update Xcode Project Settings

### Add Export Compliance Keys
In your app target's Info settings, add these keys:

1. **ITSAppUsesNonExemptEncryption**: YES
2. **ITSEncryptionExportComplianceCode**: (Will be provided by App Store Connect after first submission)

You can add these in Xcode:
1. Select your project in Xcode
2. Select your app target
3. Go to the "Info" tab
4. Add the keys under "Custom iOS Target Properties"

## Step 2: App Store Connect Configuration

### Export Compliance Information
1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app
3. Go to the "TestFlight" tab
4. Click on "Export Compliance"
5. Answer the questions as follows:

**Question 1: Does your app use encryption?**
- Answer: **Yes**

**Question 2: Does your app qualify for any of the exemptions provided in Category 5, Part 2 of the U.S. Export Administration Regulations?**
- Answer: **Yes**

**Question 3: Does your app implement any encryption algorithms that are proprietary or not accepted as standards?**
- Answer: **No**

### France-Specific Requirements
For the France declaration:
1. Select "France" in the country-specific requirements
2. Indicate that your app uses only standard iOS encryption
3. No additional declaration number is needed for apps using only iOS standard encryption

## Step 3: Annual Self-Classification Report

While your app is exempt from CCATS, you still need to submit an annual self-classification report by February 1st each year.

### How to Submit:
1. Create an email with subject: "Annual Self-Classification Report"
2. Include:
   - Your name and company
   - App name and description
   - Statement that you're using only iOS standard encryption
3. Send to:
   - crypt@bis.doc.gov
   - enc@nsa.gov

### Sample Email Template:
```
Subject: Annual Self-Classification Report - MyHome Inventory Pro

Dear BIS/NSA,

This is the annual self-classification report for:

App Name: MyHome Inventory Pro
Developer: Griffin Long
Bundle ID: com.homeinventory.app

The app uses encryption solely for:
- HTTPS/TLS communications
- iOS Data Protection APIs
- iOS Keychain Services
- LocalAuthentication framework (Face ID/Touch ID)

No custom encryption algorithms are implemented. The app uses only standard encryption provided by iOS.

ECCN: 5D992.c (Mass market software with encryption)

Sincerely,
Griffin Long
```

## Step 4: Build Settings Configuration

Add these to your build configuration:

```bash
# In your CI/CD or build script
export ENABLE_BITCODE=NO
export ITSAppUsesNonExemptEncryption=true
```

## Step 5: Fastlane Configuration (if using)

Add to your `Deliverfile`:
```ruby
export_compliance_uses_encryption(true)
export_compliance_is_exempt(true)
export_compliance_contains_third_party_cryptography(false)
export_compliance_contains_proprietary_cryptography(false)
export_compliance_available_on_french_store(true)
```

## Important Notes

1. **First Submission**: On your first TestFlight submission, App Store Connect will generate an `ITSEncryptionExportComplianceCode`. Add this to your Info.plist for future builds.

2. **Consistency**: Ensure your answers are consistent across all submissions and updates.

3. **Documentation**: Keep the `ENCRYPTION_EXPORT_COMPLIANCE.md` file updated with any changes to your encryption usage.

4. **Third-Party SDKs**: If you add any third-party SDKs that use encryption, you may need to update your compliance status.

## Common Issues and Solutions

### Issue: "Missing Compliance" warning in TestFlight
**Solution**: Ensure `ITSAppUsesNonExemptEncryption` is set to `YES` in Info.plist

### Issue: Build rejected for missing France declaration
**Solution**: Complete the export compliance questionnaire in App Store Connect before uploading

### Issue: Annual report reminder
**Solution**: Set a calendar reminder for January each year to submit the self-classification report

## Resources

- [Apple's Export Compliance Documentation](https://developer.apple.com/documentation/security/complying_with_encryption_export_regulations)
- [U.S. Bureau of Industry and Security](https://www.bis.doc.gov/index.php/policy-guidance/encryption)
- [France's ANSSI Encryption Regulations](https://www.ssi.gouv.fr/en/regulation/cryptology/)

---

*Last Updated: December 2024*