# Makefile for HomeInventory Modular App

.PHONY: help build run clean xcode test all

# Default simulator
SIMULATOR_ID = DD192264-DFAA-4582-B2FE-D6FC444C9DDF
SIMULATOR_NAME = iPhone 16 Pro Max
APP_BUNDLE_ID = com.homeinventory.modular

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

all: clean build run ## Clean, build and run the app

build: ## Build the app for simulator
	@echo "🏗️ Building HomeInventory..."
	@xcodebuild \
		-project HomeInventoryModular.xcodeproj \
		-scheme HomeInventoryModular \
		-sdk iphonesimulator \
		-configuration Debug \
		-destination "platform=iOS Simulator,id=$(SIMULATOR_ID)" \
		-derivedDataPath build \
		build | xcbeautify

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

clean: ## Clean build artifacts
	@echo "🧹 Cleaning..."
	@xcodebuild clean -project HomeInventoryModular.xcodeproj -scheme HomeInventoryModular
	@rm -rf build
	@rm -rf ~/Library/Developer/Xcode/DerivedData/HomeInventoryModular-*

xcode: ## Open project in Xcode
	@echo "📱 Opening in Xcode..."
	@open HomeInventoryModular.xcodeproj

test: ## Run tests
	@echo "🧪 Running tests..."
	@xcodebuild test \
		-project HomeInventoryModular.xcodeproj \
		-scheme HomeInventoryModular \
		-sdk iphonesimulator \
		-destination "platform=iOS Simulator,id=$(SIMULATOR_ID)" \
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

# Shortcut commands
b: build ## Shortcut for build
r: run ## Shortcut for run
br: build run ## Build and run
c: clean ## Shortcut for clean