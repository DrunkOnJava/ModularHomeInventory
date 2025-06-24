# Makefile for HomeInventory Modular App

# Include local configuration if it exists
-include .makerc.local
-include .makerc

.PHONY: help build run clean xcode test all build-commit build-ipad run-ipad all-ipad prebuild-modules

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
		SWIFT_STRICT_CONCURRENCY=minimal \
		SWIFT_SUPPRESS_WARNINGS=YES \
		| xcbeautify

generate: ## Regenerate Xcode project
	@echo "⚙️ Regenerating project..."
	@xcodegen

install-deps: ## Install required dependencies
	@echo "📦 Installing dependencies..."
	@# Check for xcbeautify
	@which xcbeautify > /dev/null || brew install xcbeautify
	@# Check for xcodegen
	@which xcodegen > /dev/null || brew install xcodegen
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

# iPad shortcuts
bi: build-ipad ## Shortcut for build-ipad
ri: run-ipad ## Shortcut for run-ipad
bri: build-ipad run-ipad ## Build and run on iPad
ai: all-ipad ## Shortcut for all-ipad

# Build with auto-commit
build-commit: ## Build and auto-commit on success
	@$(MAKE) build AUTO_COMMIT=true

bc: build-commit ## Shortcut for build-commit