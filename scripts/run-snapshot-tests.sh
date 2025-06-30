#!/bin/bash

echo "🎯 Home Inventory Snapshot Test Runner"
echo "======================================"
echo ""
echo "Select which tests to run:"
echo "1) All modules"
echo "2) Items"
echo "3) BarcodeScanner"
echo "4) Receipts"
echo "5) AppSettings"
echo "6) Premium"
echo "7) Onboarding"
echo "8) Run with recording ON (generate new snapshots)"
echo ""
read -p "Enter your choice (1-8): " choice

case $choice in
  1)
    echo "Running all module tests..."
    for script in scripts/test-runners/test-*.sh; do
      if [[ -f "$script" && "$script" != *"test-all.sh" ]]; then
        echo ""
        echo "---"
        $script
      fi
    done
    ;;
  2) ./scripts/test-runners/test-items.sh ;;
  3) ./scripts/test-runners/test-barcodescanner.sh ;;
  4) ./scripts/test-runners/test-receipts.sh ;;
  5) ./scripts/test-runners/test-appsettings.sh ;;
  6) ./scripts/test-runners/test-premium.sh ;;
  7) ./scripts/test-runners/test-onboarding.sh ;;
  8)
    echo "Which module to record? (2-7 or 1 for all): "
    read -p "Enter choice: " record_choice
    export RECORD_SNAPSHOTS=YES
    case $record_choice in
      1) $0 && choice=1 ;;  # Recursively call with choice 1
      2) ./scripts/test-runners/test-items.sh ;;
      3) ./scripts/test-runners/test-barcodescanner.sh ;;
      4) ./scripts/test-runners/test-receipts.sh ;;
      5) ./scripts/test-runners/test-appsettings.sh ;;
      6) ./scripts/test-runners/test-premium.sh ;;
      7) ./scripts/test-runners/test-onboarding.sh ;;
    esac
    ;;
  *)
    echo "Invalid choice!"
    exit 1
    ;;
esac
