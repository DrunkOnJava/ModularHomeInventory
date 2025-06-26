#!/usr/bin/env ruby

require 'fastlane'

# Direct IPA upload lane
Fastlane::FastFile.new.parse("
lane :upload_ipa do
  UI.message('📤 Uploading IPA to TestFlight...')
  
  # Upload the IPA we just created
  upload_to_testflight(
    ipa: '../build/HomeInventoryModular-1.0.6.ipa',
    app_identifier: 'com.homeinventory.app',
    app_platform: 'ios',
    team_id: '2VXBQV4XC9',
    skip_waiting_for_build_processing: true,
    skip_submission: true,
    distribute_external: false,
    changelog: '🎉 Home Inventory v1.0.6

🆕 NEW FEATURES:
• Professional Insurance Reports - Generate comprehensive PDFs for insurance providers
• View-Only Sharing Mode - Share your inventory with privacy controls

✨ IMPROVEMENTS:
• Enhanced iPad split view navigation
• Better performance with large inventories
• Improved sync reliability
• Updated SwiftLint compliance

🐛 BUG FIXES:
• Fixed item price formatting
• Resolved optional date handling
• Corrected CloudKit sync errors
• Improved error handling

Testing Focus:
• Generate insurance reports
• Test view-only sharing
• Verify privacy controls',
    beta_app_description: 'Home Inventory - The ultimate personal inventory management solution. NEW: Professional insurance reports and secure view-only sharing!',
    beta_app_feedback_email: 'griffinradcliffe@gmail.com',
    uses_non_exempt_encryption: true,
    export_compliance_uses_encryption: true,
    export_compliance_encryption_updated: false,
    export_compliance_app_type: nil,
    export_compliance_contains_third_party_cryptography: false,
    export_compliance_contains_proprietary_cryptography: false,
    export_compliance_available_on_french_store: true
  )
  
  UI.success('✅ Successfully uploaded to TestFlight!')
end
").runner.execute(:upload_ipa)