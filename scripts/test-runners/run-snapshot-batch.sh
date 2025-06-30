#!/bin/bash

# Run snapshot tests in batches for parallel execution

BATCH=$1
TOTAL_BATCHES=5

# Define test groups
declare -a TEST_GROUPS=(
    "ItemsDetailedSnapshotTests"
    "WarrantiesSnapshotTests"
    "BudgetSnapshotTests"
    "AnalyticsSnapshotTests"
    "SearchSnapshotTests"
    "DataManagementSnapshotTests"
    "BarcodeSnapshotTests"
    "ImageSearchSnapshotTests"
    "GmailSnapshotTests"
    "FamilySharingSnapshotTests"
    "SyncSnapshotTests"
    "NotificationSnapshotTests"
    "SharingSnapshotTests"
    "ErrorStateSnapshotTests"
    "LoadingStateSnapshotTests"
    "AccessibilitySnapshotTests"
    "EmptyStateSnapshotTests"
    "SuccessStateSnapshotTests"
    "FormValidationSnapshotTests"
    "ModalsSnapshotTests"
    "OnboardingSnapshotTests"
    "SettingsSnapshotTests"
    "InteractionSnapshotTests"
    "DataVisualizationSnapshotTests"
)

# Calculate which tests to run for this batch
TESTS_PER_BATCH=$((${#TEST_GROUPS[@]} / TOTAL_BATCHES))
START_INDEX=$(((BATCH - 1) * TESTS_PER_BATCH))
END_INDEX=$((START_INDEX + TESTS_PER_BATCH))

# Handle last batch
if [ $BATCH -eq $TOTAL_BATCHES ]; then
    END_INDEX=${#TEST_GROUPS[@]}
fi

echo "Running batch $BATCH of $TOTAL_BATCHES (tests $START_INDEX to $END_INDEX)"

# Run tests for this batch
for ((i=$START_INDEX; i<$END_INDEX; i++)); do
    TEST_NAME=${TEST_GROUPS[$i]}
    echo "Running $TEST_NAME..."
    
    xcodebuild test \
        -scheme HomeInventoryModular \
        -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0' \
        -only-testing:HomeInventoryModularTests/$TEST_NAME \
        -resultBundlePath TestResults/snapshot-batch-$BATCH-$TEST_NAME.xcresult \
        | xcbeautify --is-ci
    
    # Check if test failed
    if [ $? -ne 0 ]; then
        echo "❌ $TEST_NAME failed"
        # Continue with other tests
    else
        echo "✅ $TEST_NAME passed"
    fi
done

echo "Batch $BATCH completed"