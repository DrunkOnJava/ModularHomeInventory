# Terms of Service Implementation Guide

This document outlines the Terms of Service features and implementation details for ModularHomeInventory.

## Terms Documents

1. **[TERMS_OF_SERVICE.md](../TERMS_OF_SERVICE.md)** - Full Terms of Service
2. **[TERMS_OF_SERVICE_SUMMARY.md](../TERMS_OF_SERVICE_SUMMARY.md)** - Simple summary for users

## Implementation Components

### 1. Terms of Service Display
- **Location**: `Modules/AppSettings/Sources/Views/TermsOfServiceView.swift`
- **Features**:
  - Collapsible sections for easy navigation
  - Markdown support for formatting
  - Share and print options
  - Version tracking
  - Clear section organization

### 2. Combined Legal Consent Flow
- **Location**: `Modules/Onboarding/Sources/Views/LegalConsentView.swift`
- **Features**:
  - Combined Privacy Policy and Terms consent
  - Individual checkboxes for each agreement
  - Links to read full documents
  - Clear acceptance tracking

### 3. Terms Tracking
- **Location**: `Modules/Core/Sources/Models/TermsOfService.swift`
- **Features**:
  - Version tracking
  - Acceptance status
  - Date of acceptance
  - UserDefaults storage
  - Combined legal status

## Legal Framework

### Key Sections

1. **Agreement to Terms** - Binding acceptance
2. **Use License** - Personal, non-commercial use
3. **Ownership** - App vs user content rights
4. **Responsibilities** - User obligations
5. **Privacy** - Link to Privacy Policy
6. **Updates** - App and terms changes
7. **Disclaimers** - No warranties, as-is basis
8. **Liability** - Limitation of damages
9. **Termination** - Ending the agreement
10. **Legal** - Governing law and disputes

### Important Clauses

#### License Grant
- Personal use only
- Non-transferable
- Revocable
- Non-commercial

#### User Responsibilities
- Legal use only
- Accurate information
- Device security
- Data backup

#### Liability Limitations
- No consequential damages
- Limited to purchase price
- As-is basis
- No warranties

## Developer Guidelines

### When Adding Features

1. **Consider**: Does this change user rights or responsibilities?
2. **Update**: Modify terms if new obligations are created
3. **Version**: Increment version number for material changes
4. **Notify**: Plan user notification for changes

### Terms Update Process

1. Update `TERMS_OF_SERVICE.md`
2. Update `TERMS_OF_SERVICE_SUMMARY.md`
3. Increment version in `TermsOfService.swift`
4. Update effective date
5. Add changelog entry
6. Consider re-consent requirements
7. Plan notification strategy

### Integration Points

#### Onboarding
```swift
// Check if user has accepted current terms
if !TermsOfServiceVersion.hasAcceptedCurrentVersion {
    // Show LegalConsentView
}
```

#### Settings
```swift
// Allow users to review terms anytime
NavigationLink("Terms of Service") {
    TermsOfServiceView()
}
```

#### Updates
```swift
// Check for new version on app launch
if userAcceptedVersion != TermsOfServiceVersion.current {
    // Show update notification
}
```

## Testing Terms

### Manual Tests
1. Fresh install - verify consent flow
2. Terms acceptance - check storage
3. Decline flow - app should exit
4. Settings access - review anytime
5. Version update - re-consent if needed

### Acceptance Verification
```swift
// Check legal status
let status = LegalAcceptanceStatus.current
if status.allAccepted {
    // User has accepted both privacy and terms
}
```

## Legal Compliance Checklist

### App Store Requirements
- [ ] Clear terms accessible
- [ ] Age restriction (13+)
- [ ] License terms defined
- [ ] Privacy policy linked
- [ ] Contact information

### User Rights
- [ ] Data ownership clarified
- [ ] Export capabilities
- [ ] Deletion rights
- [ ] License scope defined
- [ ] Termination process

### Protections
- [ ] Liability limitations
- [ ] Warranty disclaimers
- [ ] Indemnification
- [ ] Dispute resolution
- [ ] Governing law

## Common Scenarios

### New User
1. Downloads app
2. Sees LegalConsentView
3. Reviews both agreements
4. Must accept both to proceed
5. Acceptance recorded

### Returning User
1. App checks acceptance status
2. If current version accepted, proceed
3. If new version, show update notice
4. Re-consent if material changes

### Settings Access
1. User can always view terms
2. Located in Settings > Legal
3. Can share or print
4. Version clearly displayed

## Best Practices

1. **Plain Language** - Keep terms understandable
2. **Highlight Changes** - Clear version tracking
3. **Easy Access** - Available in settings
4. **Consent Records** - Track acceptance properly
5. **Regular Review** - Update with app changes

## Contact

For legal questions or updates:
- Email: legal@modularhomeinventory.com
- Review cycle: Quarterly
- Update notifications: In-app

---

Last Updated: June 24, 2025