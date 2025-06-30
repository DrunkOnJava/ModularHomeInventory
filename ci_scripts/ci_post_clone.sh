#!/bin/sh
# Xcode Cloud Post-Clone Script
# This runs after the repository is cloned but before dependencies are resolved

set -e

echo "🔄 Running post-clone setup..."

# Make all scripts executable
echo "🔑 Setting script permissions..."
chmod +x ci_scripts/*.sh
chmod +x scripts/*.sh || true

# Setup Ruby environment
echo "💎 Setting up Ruby environment..."
if command -v rbenv &> /dev/null; then
    eval "$(rbenv init -)"
fi

# Install bundler if needed
if ! command -v bundle &> /dev/null; then
    echo "📦 Installing bundler..."
    gem install bundler
fi

# Create necessary directories
echo "📁 Creating required directories..."
mkdir -p Generated
mkdir -p Generated/Arkana
mkdir -p TestResults
mkdir -p BuildArtifacts
mkdir -p docs/diagrams

# Setup example configuration files if needed
if [ ! -f ".env.arkana" ] && [ -f ".env.arkana.example" ]; then
    echo "📝 Creating .env.arkana from example..."
    cp .env.arkana.example .env.arkana
fi

# Cache Homebrew packages for faster builds
echo "🍺 Updating Homebrew..."
brew update || true

echo "✅ Post-clone setup complete!"