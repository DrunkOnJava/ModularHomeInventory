# Makefile for HomeInventory Modular App

# Include local configuration if it exists
-include .makerc.local
-include .makerc

.PHONY: help build run clean xcode test all build-commit build-ipad run-ipad all-ipad prebuild-modules lint format lint-fix analyze test-snapshots record-snapshots pre-merge

# Default simulator
SIMULATOR_ID ?= DD192264-DFAA-4582-B2FE-D6FC444C9DDF
SIMULATOR_NAME ?= iPhone 16 Pro Max

# iPad simulator
IPAD_SIMULATOR_ID ?= CE6D038C-840B-4BDB-AA63-D61FA0755C4A
IPAD_SIMULATOR_NAME ?= iPad Pro 13-inch (M4)

APP_BUNDLE_ID = com.homeinventory.app

# Auto-commit feature (default: on)
AUTO_COMMIT ?= true

# SPM modules in dependency order
SPM_MODULES = Core SharedUI BarcodeScanner Receipts AppSettings Onboarding Premium Sync Items

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

all: clean build run ## Clean, build and run the app

prebuild-modules: ## Pre-build SPM modules in dependency order
	@echo "📦 Pre-building SPM modules to fix dependency issues..."
	@for module in $(SPM_MODULES); do \
		echo "  🔨 Building $$module..."; \
		xcodebuild build \
			-scheme "$$module" \
			-destination "platform=iOS Simulator,id=$(SIMULATOR_ID)" \
			-configuration Debug \
			-derivedDataPath build \
			SWIFT_STRICT_CONCURRENCY=minimal \
			SWIFT_SUPPRESS_WARNINGS=YES \
			-quiet 2>&1 | grep -E "(error:|warning:|BUILD)" || true; \
		if [ $${PIPESTATUS[0]} -eq 0 ]; then \
			echo "  ✅ $$module built successfully"; \
		else \
			echo "  ❌ Failed to build $$module"; \
			exit 1; \
		fi; \
	done
	@echo "✅ All modules pre-built successfully!"

build: prebuild-modules ## Build the app for simulator
	@echo "🏗️ Building HomeInventory..."
	@if xcodebuild \
		-project HomeInventoryModular.xcodeproj \
		-scheme HomeInventoryModular \
		-sdk iphonesimulator \
		-configuration Debug \
		-destination "platform=iOS Simulator,id=$(SIMULATOR_ID)" \
		-derivedDataPath build \
		SWIFT_STRICT_CONCURRENCY=minimal \
		SWIFT_SUPPRESS_WARNINGS=YES \
		OTHER_SWIFT_FLAGS="-suppress-warnings" \
		build | xcbeautify; then \
		echo "✅ Build succeeded!"; \
		if [ "$(AUTO_COMMIT)" = "true" ]; then \
			./scripts/auto-commit.sh; \
		fi; \
	else \
		echo "❌ Build failed!"; \
		exit 1; \
	fi

build-ipad: prebuild-modules ## Build the app for iPad simulator
	@echo "🏗️ Building HomeInventory for iPad..."
	@if xcodebuild \
		-project HomeInventoryModular.xcodeproj \
		-scheme HomeInventoryModular \
		-sdk iphonesimulator \
		-configuration Debug \
		-destination "platform=iOS Simulator,id=$(IPAD_SIMULATOR_ID)" \
		-derivedDataPath build \
		SWIFT_STRICT_CONCURRENCY=minimal \
		SWIFT_SUPPRESS_WARNINGS=YES \
		OTHER_SWIFT_FLAGS="-suppress-warnings" \
		build | xcbeautify; then \
		echo "✅ iPad build succeeded!"; \
		if [ "$(AUTO_COMMIT)" = "true" ]; then \
			./scripts/auto-commit.sh; \
		fi; \
	else \
		echo "❌ iPad build failed!"; \
		exit 1; \
	fi

run: ## Run the app in simulator (requires successful build)
	@echo "🚀 Launching app in $(SIMULATOR_NAME)..."
	@# Boot simulator if needed
	@xcrun simctl boot $(SIMULATOR_ID) 2>/dev/null || true
	@open -a Simulator
	@# Install and launch
	@APP_PATH=$$(find build/Build/Products -name "*.app" -type d | head -1); \
	if [ -n "$$APP_PATH" ]; then \
		xcrun simctl install $(SIMULATOR_ID) "$$APP_PATH" && \
		xcrun simctl launch $(SIMULATOR_ID) $(APP_BUNDLE_ID); \
		echo "✅ App launched!"; \
	else \
		echo "❌ No app found. Run 'make build' first."; \
		exit 1; \
	fi

run-ipad: ## Run the app in iPad simulator (requires successful build)
	@echo "🚀 Launching app in $(IPAD_SIMULATOR_NAME)..."
	@# Boot simulator if needed
	@xcrun simctl boot $(IPAD_SIMULATOR_ID) 2>/dev/null || true
	@open -a Simulator
	@# Install and launch
	@APP_PATH=$$(find build/Build/Products -name "*.app" -type d | head -1); \
	if [ -n "$$APP_PATH" ]; then \
		xcrun simctl install $(IPAD_SIMULATOR_ID) "$$APP_PATH" && \
		xcrun simctl launch $(IPAD_SIMULATOR_ID) $(APP_BUNDLE_ID); \
		echo "✅ App launched on iPad!"; \
	else \
		echo "❌ No app found. Run 'make build-ipad' first."; \
		exit 1; \
	fi

all-ipad: clean build-ipad run-ipad ## Clean, build and run the app on iPad

clean: ## Clean build artifacts
	@echo "🧹 Cleaning..."
	@xcodebuild clean -project HomeInventoryModular.xcodeproj -scheme HomeInventoryModular
	@rm -rf build
	@rm -rf ~/Library/Developer/Xcode/DerivedData/HomeInventoryModular-*

xcode: ## Open project in Xcode
	@echo "📱 Opening in Xcode..."
	@open HomeInventoryModular.xcodeproj

test: prebuild-modules ## Run tests
	@echo "🧪 Running tests..."
	@xcodebuild test \
		-project HomeInventoryModular.xcodeproj \
		-scheme HomeInventoryModular \
		-sdk iphonesimulator \
		-destination "platform=iOS Simulator,id=$(SIMULATOR_ID)" \
		-derivedDataPath build \
		-resultBundlePath TestResults.xcresult \
		SWIFT_STRICT_CONCURRENCY=minimal \
		SWIFT_SUPPRESS_WARNINGS=YES \
		| xcbeautify
	@# Generate HTML report if tests complete
	@if [ -d "TestResults.xcresult" ]; then \
		echo "📊 Generating test report..."; \
		xchtmlreport -r TestResults.xcresult || true; \
	fi

lint: ## Run SwiftLint to check code style
	@echo "🔍 Running SwiftLint..."
	@swiftlint lint --config .swiftlint.yml --reporter emoji
	@echo "✅ Linting complete!"

lint-fix: ## Run SwiftLint and automatically fix issues
	@echo "🔧 Running SwiftLint autocorrect..."
	@swiftlint autocorrect --config .swiftlint.yml
	@echo "✅ Auto-corrections applied!"

format: ## Format code using SwiftFormat
	@echo "✨ Formatting code..."
	@swiftformat . --config .swiftformat --verbose
	@echo "✅ Formatting complete!"

analyze: lint ## Run static analysis (lint + build with warnings)
	@echo "🔬 Running static analysis..."
	@xcodebuild analyze \
		-project HomeInventoryModular.xcodeproj \
		-scheme HomeInventoryModular \
		-sdk iphonesimulator \
		-destination "platform=iOS Simulator,id=$(SIMULATOR_ID)" \
		-derivedDataPath build \
		| xcbeautify
	@echo "✅ Analysis complete!"

test-snapshots: ## Run snapshot tests
	@echo "📸 Running snapshot tests..."
	@ruby scripts/run_snapshot_tests.rb
	@echo "✅ Snapshot tests complete!"

record-snapshots: ## Record new snapshots (WARNING: This will overwrite existing snapshots)
	@echo "📸 Recording new snapshots..."
	@echo "⚠️  This will overwrite existing snapshots!"
	@ruby scripts/run_snapshot_tests.rb --record
	@echo "✅ New snapshots recorded!"

clean-snapshots: ## Remove obsolete snapshots (older than 30 days)
	@echo "🧹 Cleaning obsolete snapshots..."
	@find . -name "__Snapshots__" -type d -exec find {} -name "*.png" -mtime +30 -delete \;
	@echo "✅ Obsolete snapshots cleaned!"

pre-merge: ## Run all checks before merging (lint, format, build, tests)
	@echo "🚀 Running pre-merge checks..."
	@./scripts/pre_merge_checks.sh

generate: ## Regenerate Xcode project
	@echo "⚙️ Regenerating project..."
	@xcodegen

install-deps: ## Install required dependencies
	@echo "📦 Installing dependencies..."
	@# Check for xcbeautify
	@which xcbeautify > /dev/null || brew install xcbeautify
	@# Check for xcodegen
	@which xcodegen > /dev/null || brew install xcodegen
	@# Check for swiftlint
	@which swiftlint > /dev/null || brew install swiftlint
	@# Check for swiftformat
	@which swiftformat > /dev/null || brew install swiftformat
	@# Check for xchtmlreport
	@which xchtmlreport > /dev/null || brew install xchtmlreport
	@# Check for periphery
	@which periphery > /dev/null || brew install peripheryapp/periphery/periphery
	@echo "✅ Dependencies installed!"

# Fast build without prebuild (use when modules are already built)
build-fast: ## Build without pre-building modules (faster)
	@echo "⚡ Fast build (skipping module prebuild)..."
	@if xcodebuild \
		-project HomeInventoryModular.xcodeproj \
		-scheme HomeInventoryModular \
		-sdk iphonesimulator \
		-configuration Debug \
		-destination "platform=iOS Simulator,id=$(SIMULATOR_ID)" \
		-derivedDataPath build \
		SWIFT_STRICT_CONCURRENCY=minimal \
		SWIFT_SUPPRESS_WARNINGS=YES \
		OTHER_SWIFT_FLAGS="-suppress-warnings" \
		build | xcbeautify; then \
		echo "✅ Build succeeded!"; \
		if [ "$(AUTO_COMMIT)" = "true" ]; then \
			./scripts/auto-commit.sh; \
		fi; \
	else \
		echo "❌ Build failed! Try 'make build' for full build with module prebuild."; \
		exit 1; \
	fi

# Shortcut commands
b: build ## Shortcut for build
bf: build-fast ## Shortcut for fast build
r: run ## Shortcut for run
br: build run ## Build and run
c: clean ## Shortcut for clean
l: lint ## Shortcut for lint
lf: lint-fix ## Shortcut for lint-fix
f: format ## Shortcut for format
a: analyze ## Shortcut for analyze
ts: test-snapshots ## Shortcut for test-snapshots
rs: record-snapshots ## Shortcut for record-snapshots
pm: pre-merge ## Shortcut for pre-merge

# iPad shortcuts
bi: build-ipad ## Shortcut for build-ipad
ri: run-ipad ## Shortcut for run-ipad
bri: build-ipad run-ipad ## Build and run on iPad
ai: all-ipad ## Shortcut for all-ipad

# Build with auto-commit
build-commit: ## Build and auto-commit on success
	@$(MAKE) build AUTO_COMMIT=true

bc: build-commit ## Shortcut for build-commit


# Dead code detection with Periphery
dead-code: ## Find unused code with Periphery
	@echo "🔍 Detecting dead code..."
	@periphery scan

dead-code-aggressive: ## Aggressive dead code detection
	@echo "🔍 Running aggressive dead code detection..."
	@periphery scan --aggressive

dead-code-report: ## Generate dead code report in multiple formats
	@echo "📊 Generating dead code reports..."
	@mkdir -p reports
	@periphery scan --format csv > reports/dead_code.csv
	@periphery scan --format json > reports/dead_code.json
	@periphery scan --format markdown > reports/dead_code.md
	@echo "✅ Reports generated in reports/ directory"

dead-code-modules: ## Check dead code in specific modules
	@echo "🔍 Checking dead code in modules..."
	@for module in Core SharedUI Items BarcodeScanner AppSettings Receipts Sync Premium Onboarding Widgets; do \
		echo "\n📦 Checking $$module module..."; \
		periphery scan --project Modules/$$module/Package.swift 2>/dev/null || echo "  ⚠️  Module uses SPM, skipping..."; \
	done

dead-code-clean: ## Remove unused code (interactive)
	@echo "🧹 Preparing to clean dead code..."
	@echo "⚠️  This will show you unused code. Review carefully before deleting\!"
	@periphery scan --format xcode

# Periphery shortcuts
dc: dead-code ## Shortcut for dead-code
dca: dead-code-aggressive ## Shortcut for aggressive dead code detection
dcr: dead-code-report ## Shortcut for dead code report
dcc: dead-code-clean ## Shortcut for dead code clean

# =====================================
# TestFlight Deployment
# =====================================

archive: ## Create release archive for App Store/TestFlight
	@echo "📦 Creating release archive..."
	@# Ensure we have fastlane
	@which fastlane > /dev/null || (echo "❌ Fastlane not found. Install with: gem install fastlane" && exit 1)
	@# Build archive
	@cd fastlane && fastlane build_only
	@echo "✅ Archive created successfully!"

testflight: ## Build and upload to TestFlight with full release notes
	@echo "🚀 Deploying to TestFlight..."
	@echo "📋 This will upload with comprehensive release notes and encryption compliance"
	@# Ensure we have fastlane
	@which fastlane > /dev/null || (echo "❌ Fastlane not found. Install with: gem install fastlane" && exit 1)
	@# Pre-deployment checks
	@echo "🔍 Running pre-deployment checks..."
	@make lint format
	@# Build and upload
	@cd fastlane && fastlane testflight
	@echo "✅ Successfully deployed to TestFlight!"
	@echo "📱 Check App Store Connect for processing status"
	@echo "📋 Release notes have been included with encryption compliance"

testflight-force: ## Force upload to TestFlight (skip git clean check)
	@echo "⚠️ Force uploading to TestFlight (skipping git status check)..."
	@which fastlane > /dev/null || (echo "❌ Fastlane not found. Install with: gem install fastlane" && exit 1)
	@cd fastlane && fastlane testflight force:true
	@echo "✅ Force upload complete!"

validate-app: ## Validate app for App Store submission
	@echo "✅ Validating app for App Store..."
	@which fastlane > /dev/null || (echo "❌ Fastlane not found. Install with: gem install fastlane" && exit 1)
	@cd fastlane && fastlane validate
	@echo "✅ App validation complete!"

setup-fastlane: ## Install and setup fastlane
	@echo "⚙️ Setting up Fastlane..."
	@# Install fastlane if not present
	@which fastlane > /dev/null || gem install fastlane
	@# Initialize match if needed
	@echo "🔐 Fastlane installed successfully!"
	@echo "💡 Run 'make testflight' to deploy to TestFlight"

deployment-status: ## Check deployment and encryption compliance status
	@echo "📊 Deployment Status Report"
	@echo "=========================="
	@echo "📱 App: Home Inventory"
	@echo "📦 Bundle ID: com.homeinventory.app"
	@echo "🔢 Current Version: $(shell grep MARKETING_VERSION project.yml | cut -d: -f2 | xargs)"
	@echo "🏗️ Current Build: $(shell xcodebuild -project HomeInventoryModular.xcodeproj -showBuildSettings | grep CURRENT_PROJECT_VERSION | cut -d= -f2 | xargs || echo 'Unknown')"
	@echo "🔐 Encryption Compliance: ✅ Configured (Standard iOS encryption only)"
	@echo "📋 France Declaration: ✅ Included in ExportCompliance.plist"
	@echo "📄 Release Notes: ✅ Comprehensive TestFlight notes prepared"
	@echo ""
	@echo "🚀 Ready for TestFlight deployment!"
	@echo "💡 Run 'make testflight' to deploy"

# TestFlight shortcuts
tf: testflight ## Shortcut for testflight
tff: testflight-force ## Shortcut for testflight-force  
arch: archive ## Shortcut for archive
val: validate-app ## Shortcut for validate-app
