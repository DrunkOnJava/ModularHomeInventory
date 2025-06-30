#!/bin/bash

# Claude with Keychain Integration
# Loads MCP API keys from macOS Keychain before starting Claude

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load API keys from keychain
echo "Loading MCP API keys from Keychain..."

# Helper function to get key from keychain
get_keychain_value() {
    local service=$1
    security find-generic-password -s "$service" -w 2>/dev/null || echo ""
}

# Export environment variables from keychain
export GITHUB_PERSONAL_ACCESS_TOKEN=$(get_keychain_value "mcp-github-token")
export BRAVE_API_KEY=$(get_keychain_value "mcp-brave-api-key")
export GOOGLE_MAPS_API_KEY=$(get_keychain_value "mcp-google-maps-api-key")
export SLACK_BOT_TOKEN=$(get_keychain_value "mcp-slack-bot-token")
export SLACK_TEAM_ID=$(get_keychain_value "mcp-slack-team-id")
export EVERART_API_KEY=$(get_keychain_value "mcp-everart-api-key")
export POSTGRES_CONNECTION_STRING=$(get_keychain_value "mcp-postgres-connection-string")

# Count loaded keys
loaded_count=0
[ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ] && ((loaded_count++))
[ -n "$BRAVE_API_KEY" ] && ((loaded_count++))
[ -n "$GOOGLE_MAPS_API_KEY" ] && ((loaded_count++))
[ -n "$SLACK_BOT_TOKEN" ] && ((loaded_count++))
[ -n "$SLACK_TEAM_ID" ] && ((loaded_count++))
[ -n "$EVERART_API_KEY" ] && ((loaded_count++))
[ -n "$POSTGRES_CONNECTION_STRING" ] && ((loaded_count++))

echo "Loaded $loaded_count API keys from Keychain"

# Start Claude with the environment variables
echo "Starting Claude..."
cd "$PROJECT_ROOT"
exec claude "$@"