# Encryption Export Compliance Documentation

## App Information
- **App Name**: MyHome Inventory Pro
- **Bundle ID**: com.homeinventory.app
- **Version**: 1.0.0
- **Developer**: Griffin Long

## Encryption Declaration

This app uses encryption for the following purposes:

### 1. HTTPS Communications
- The app uses standard HTTPS (TLS/SSL) for all network communications
- This includes API calls and data synchronization
- Uses iOS standard URLSession with default encryption

### 2. Local Data Encryption
- Uses iOS Data Protection APIs for local storage
- Core Data with encryption enabled
- Keychain Services for sensitive data (authentication tokens)

### 3. Authentication
- Biometric authentication (Face ID/Touch ID) using LocalAuthentication framework
- No custom encryption algorithms implemented

### 4. Third-Party Services
- iCloud sync using CloudKit (Apple's encrypted sync service)
- No third-party encryption libraries

## Export Compliance

### ECCN Classification
This app qualifies for encryption exemption under **ECCN 5D992.c** with mass market encryption.

### Self-Classification Report
- **CCATS Required**: No
- **Encryption Type**: Standard encryption inherent to iOS
- **Encryption Strength**: Industry standard (AES-256)
- **Open Source Encryption**: No
- **Proprietary Encryption**: No
- **Key Length**: Standard iOS encryption (up to 256-bit)

### France Declaration
In compliance with French encryption regulations:
- This app uses only standard encryption provided by iOS
- No custom cryptographic implementations
- Encryption is used solely for data protection and secure communications
- The app does not provide encryption as a service to users

## Exemption Justification

This app qualifies for export under the mass market exemption because:

1. It uses only standard encryption inherent to the iOS platform
2. The primary function is inventory management, not encryption
3. Encryption is used solely for:
   - Protecting user data at rest
   - Securing data in transit
   - Standard authentication mechanisms
4. No encryption functionality is exposed to end users
5. The app cannot be used as a general encryption tool

## Annual Self-Classification Report

An annual self-classification report will be submitted to:
- Email: crypt@bis.doc.gov
- Email: enc@nsa.gov

## Contact Information

**Developer Contact**:
- Name: Griffin Long
- Email: griffinradcliffe@gmail.com
- Company: Individual Developer

---

*Last Updated: December 2024*