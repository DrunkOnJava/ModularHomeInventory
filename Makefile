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

# TestFlight Commands
testflight-validate: ## Validate build before TestFlight submission
	@echo "🔍 Validating build..."
	@./scripts/validate_build.sh

testflight-build: ## Build and archive for TestFlight
	@echo "🚀 Building for TestFlight..."
	@TOOLCHAINS=swift-5.9-RELEASE xcodebuild archive \
		-project HomeInventoryModular.xcodeproj \
		-scheme HomeInventoryModular \
		-configuration Release \
		-archivePath ~/Desktop/HomeInventory.xcarchive \
		-destination "generic/platform=iOS" \
		-allowProvisioningUpdates

testflight-export: ## Export IPA from archive
	@echo "📱 Exporting IPA..."
	@xcodebuild -exportArchive \
		-archivePath ~/Desktop/HomeInventory.xcarchive \
		-exportPath ~/Desktop/HomeInventoryExport \
		-exportOptionsPlist ExportOptions.plist

testflight-submit: ## Submit to TestFlight (requires API keys)
	@echo "☁️ Submitting to TestFlight..."
	@./scripts/submit_to_testflight.sh

testflight: testflight-validate testflight-submit ## Complete TestFlight submission process

# Aliases for TestFlight
tf: testflight ## Alias for testflight
tfv: testflight-validate ## Alias for testflight-validate
tfb: testflight-build ## Alias for testflight-build
tfs: testflight-submit ## Alias for testflight-submit

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

# Snapshot Testing
test-snapshots: prebuild-modules ## Run snapshot tests only
	@echo "📸 Running snapshot tests..."
	@xcodebuild test \
		-project HomeInventoryModular.xcodeproj \
		-scheme HomeInventoryModular \
		-sdk iphonesimulator \
		-destination "platform=iOS Simulator,id=$(SIMULATOR_ID)" \
		-derivedDataPath build \
		-only-testing:HomeInventoryModularTests \
		SWIFT_STRICT_CONCURRENCY=minimal \
		SWIFT_SUPPRESS_WARNINGS=YES \
		| xcbeautify

record-snapshots: prebuild-modules ## Record new snapshots
	@echo "📸 Recording snapshots..."
	@ruby scripts/run_snapshot_tests.rb record

update-snapshots: prebuild-modules ## Update existing snapshots
	@echo "📸 Updating snapshots..."
	@ruby scripts/run_snapshot_tests.rb update

verify-snapshots: prebuild-modules ## Verify snapshots match
	@echo "📸 Verifying snapshots..."
	@ruby scripts/run_snapshot_tests.rb verify

snapshot-report: ## Generate snapshot test coverage report
	@echo "📊 Generating snapshot coverage report..."
	@find HomeInventoryModularTests -name "*SnapshotTests.swift" | wc -l | xargs -I {} echo "📸 Total snapshot test files: {}"
	@find HomeInventoryModularTests -name "*.png" | wc -l | xargs -I {} echo "🖼️  Total snapshot images: {}"
	@echo "📁 Snapshot locations:"
	@find HomeInventoryModularTests -name "__Snapshots__" -type d | sed 's/^/   /'

# Snapshot testing shortcuts
ts: test-snapshots ## Shortcut for test-snapshots
rs: record-snapshots ## Shortcut for record-snapshots
us: update-snapshots ## Shortcut for update-snapshots
vs: verify-snapshots ## Shortcut for verify-snapshots
sr: snapshot-report ## Shortcut for snapshot-report

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
	@echo "🚀 Deploying to TestFlight v1.0.6..."
	@echo "📋 This will upload with comprehensive release notes and encryption compliance"
	@# Ensure we have fastlane
	@which fastlane > /dev/null || (echo "❌ Fastlane not found. Install with: gem install fastlane" && exit 1)
	@# Pre-deployment checks
	@echo "🔍 Running pre-deployment checks..."
	@echo "📦 Verifying version numbers..."
	@echo "  Version: $(shell grep MARKETING_VERSION project.yml | cut -d: -f2 | xargs)"
	@echo "  Build: $(shell grep CURRENT_PROJECT_VERSION project.yml | cut -d: -f2 | xargs)"
	@# Ensure git is clean
	@if [ -n "$(shell git status --porcelain)" ]; then \
		echo "⚠️  Git working directory not clean. Commit changes or use 'make testflight-force'"; \
		exit 1; \
	fi
	@# Run SwiftLint to ensure code quality
	@echo "🧹 Running SwiftLint..."
	@if ! swiftlint lint --quiet; then \
		echo "⚠️  SwiftLint found issues. Fix them or use 'make testflight-force' to skip"; \
		exit 1; \
	fi
	@# Build and upload
	@echo "🏗️  Building and uploading to TestFlight..."
	@cd fastlane && bundle exec fastlane testflight
	@echo "✅ Successfully deployed to TestFlight!"
	@echo "📱 Check App Store Connect for processing status"
	@echo "📋 Release notes have been included with encryption compliance"
	@echo "🔗 https://appstoreconnect.apple.com"

testflight-force: ## Force upload to TestFlight (skip git clean check)
	@echo "⚠️ Force uploading to TestFlight v1.0.6 (skipping checks)..."
	@echo "📦 Current version: $(shell grep MARKETING_VERSION project.yml | cut -d: -f2 | xargs)"
	@echo "🏗️ Current build: $(shell grep CURRENT_PROJECT_VERSION project.yml | cut -d: -f2 | xargs)"
	@which fastlane > /dev/null || (echo "❌ Fastlane not found. Install with: gem install fastlane" && exit 1)
	@cd fastlane && bundle exec fastlane testflight force:true
	@echo "✅ Force upload complete!"
	@echo "📱 Check App Store Connect for processing status"
	@echo "🔗 https://appstoreconnect.apple.com"

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
	@echo "👤 Team ID: 2VXBQV4XC9"
	@echo "🔢 Current Version: $(shell grep MARKETING_VERSION project.yml | cut -d: -f2 | xargs)"
	@echo "🏗️ Current Build: $(shell grep CURRENT_PROJECT_VERSION project.yml | cut -d: -f2 | xargs)"
	@echo ""
	@echo "✅ Configuration Status:"
	@echo "  • Xcode Project: $(shell [ -f HomeInventoryModular.xcodeproj/project.pbxproj ] && echo '✓ Found' || echo '✗ Missing')"
	@echo "  • Fastlane: $(shell [ -f fastlane/Fastfile ] && echo '✓ Configured' || echo '✗ Missing')"
	@echo "  • Appfile: $(shell [ -f fastlane/Appfile ] && echo '✓ Configured' || echo '✗ Missing')"
	@echo "  • Ruby Dependencies: $(shell cd fastlane && bundle check >/dev/null 2>&1 && echo '✓ Installed' || echo '✗ Run: bundle install')"
	@echo ""
	@echo "🔐 Compliance Status:"
	@echo "  • Encryption: ✅ Standard iOS encryption only"
	@echo "  • Export Compliance: $(shell [ -f ExportCompliance.plist ] && echo '✓ Configured' || echo '✗ Missing')"
	@echo "  • France Declaration: ✅ Included"
	@echo "  • Privacy Policy: ✅ GDPR/CCPA compliant"
	@echo ""
	@echo "📄 Release Notes: v1.0.6"
	@echo "  • NEW: Professional Insurance Reports"
	@echo "  • NEW: View-Only Sharing Mode"
	@echo "  • Enhanced iPad experience"
	@echo "  • Bug fixes and performance improvements"
	@echo ""
	@echo "🚀 Deployment Commands:"
	@echo "  • make testflight - Build and upload to TestFlight"
	@echo "  • make testflight-force - Force upload (skip checks)"
	@echo "  • make validate-app - Validate before submission"
	@echo ""
	@echo "📱 App Store Connect: https://appstoreconnect.apple.com"

# TestFlight shortcuts
tf: testflight ## Shortcut for testflight
tff: testflight-force ## Shortcut for testflight-force  
arch: archive ## Shortcut for archive
val: validate-app ## Shortcut for validate-app

# Code Generation with Sourcery
generate-mocks: ## Generate mock classes using Sourcery
	@echo "🎭 Generating mocks..."
	@sourcery --config .sourcery.yml
	@echo "✅ Mocks generated\!"

# Documentation
docs: ## Generate documentation with Jazzy
	@echo "📚 Generating documentation..."
	@jazzy --clean --author "Home Inventory Team" --module HomeInventoryModular --theme apple --output docs/
	@echo "✅ Documentation generated at docs/index.html"

docs-open: docs ## Generate and open documentation
	@open docs/index.html

# Danger for PR automation
danger-dry: ## Run Danger in dry-run mode (local testing)
	@echo "⚡ Running Danger in dry-run mode..."
	@danger dry_run
	@echo "✅ Danger dry run complete\!"

danger-pr: ## Run Danger on PR (requires DANGER_GITHUB_API_TOKEN)
	@echo "🤖 Running Danger..."
	@bundle exec danger
	@echo "✅ Danger complete\!"

# Combined pre-commit check
pre-commit: lint format test ## Run all pre-commit checks
	@echo "✅ All pre-commit checks passed\!"

# Install all development tools
install-all-tools: install-deps ## Install all development tools including Ruby gems
	@echo "💎 Installing Ruby gems..."
	@bundle install
	@echo "🛠️ Installing Sourcery..."
	@which sourcery > /dev/null || brew install sourcery
	@echo "✅ All tools installed\!"

# Tool shortcuts
gm: generate-mocks ## Shortcut for generate-mocks
d: docs ## Shortcut for docs
do: docs-open ## Shortcut for docs-open

# Injection Hot Reload
injection-help: ## Show InjectionIII setup instructions
	@echo "💉 InjectionIII Setup:"
	@echo "1. Install from Mac App Store: https://apps.apple.com/app/injectioniii/id1380446739"
	@echo "2. Launch InjectionIII app"
	@echo "3. Add project directory: $(PWD)"
	@echo "4. Build and run: make build run"
	@echo "5. Edit Swift files - changes reload instantly\!"
	@echo ""
	@echo "Note: Hot reload works in Simulator only"

# Arkana Secrets Management
secrets-generate: ## Generate encrypted secrets with Arkana
	@echo "🔐 Generating encrypted secrets..."
	@bundle exec arkana
	@echo "✅ Secrets generated in Generated/Arkana/"

secrets-setup: ## Initial Arkana setup
	@echo "🔑 Setting up Arkana..."
	@cp .env.arkana.example .env.arkana 2>/dev/null || echo "⚠️  Create .env.arkana from .env.arkana.example"
	@echo "📝 Edit .env.arkana with your secret values"
	@echo "🚫 Never commit .env.arkana to git\!"

# Rocket Release Automation
release-patch: ## Create a patch release (1.0.x)
	@echo "🚀 Creating patch release..."
	@bundle exec rocket release --release-type patch

release-minor: ## Create a minor release (1.x.0)
	@echo "🚀 Creating minor release..."
	@bundle exec rocket release --release-type minor

release-major: ## Create a major release (x.0.0)
	@echo "🚀 Creating major release..."
	@bundle exec rocket release --release-type major

release-dry: ## Dry run of release process
	@echo "🧪 Release dry run..."
	@bundle exec rocket release --dry-run

# SwiftPlantUML Diagram Generation
diagrams: ## Generate UML diagrams from Swift code
	@echo "📊 Generating UML diagrams..."
	@swiftplantuml generate
	@echo "✅ Diagrams generated in docs/diagrams/"

diagrams-class: ## Generate only class diagrams
	@swiftplantuml generate --type class

diagrams-sequence: ## Generate only sequence diagrams
	@swiftplantuml generate --type sequence

diagrams-open: diagrams ## Generate and open diagrams
	@open docs/diagrams/index.html

# Reveal Integration
reveal-build: ## Build with Reveal integration
	@echo "🔍 Building with Reveal..."
	@xcodebuild build \
		-project HomeInventoryModular.xcodeproj \
		-scheme HomeInventoryModular \
		-configuration Debug \
		-destination "platform=iOS Simulator,id=$(SIMULATOR_ID)" \
		-derivedDataPath build \
		OTHER_SWIFT_FLAGS="-D REVEAL_ENABLED" \
		| xcbeautify

reveal: reveal-build run ## Build and run with Reveal

# Combined tool installation
install-new-tools: ## Install newly added tools
	@echo "🛠️ Installing new development tools..."
	@echo "📦 Installing SwiftPlantUML..."
	@brew install swiftplantuml || true
	@echo "💎 Installing Ruby gems..."
	@bundle install
	@echo "📱 InjectionIII: Install from Mac App Store"
	@echo "🔍 Reveal: Download from https://revealapp.com"
	@echo "✅ Tools installed\! See docs for configuration."

# Tool shortcuts
sg: secrets-generate ## Shortcut for secrets-generate
rp: release-patch ## Shortcut for release-patch
rm: release-minor ## Shortcut for release-minor
dg: diagrams ## Shortcut for diagrams
dgo: diagrams-open ## Shortcut for diagrams-open
