#!/bin/bash

# MCP Keychain Manager
# Manages API keys for MCP servers using macOS Keychain

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Service name mapping function
get_keychain_service() {
    case "$1" in
        "github") echo "mcp-github-token" ;;
        "brave") echo "mcp-brave-api-key" ;;
        "google-maps") echo "mcp-google-maps-api-key" ;;
        "slack-bot") echo "mcp-slack-bot-token" ;;
        "slack-team") echo "mcp-slack-team-id" ;;
        "everart") echo "mcp-everart-api-key" ;;
        "postgres") echo "mcp-postgres-connection-string" ;;
        *) echo "" ;;
    esac
}

# List of all services
SERVICES="github brave google-maps slack-bot slack-team everart postgres"

function show_usage() {
    echo "Usage: $0 <command> [service] [value]"
    echo ""
    echo "Commands:"
    echo "  set <service> <value>  - Store API key in keychain"
    echo "  get <service>          - Retrieve API key from keychain"
    echo "  delete <service>       - Remove API key from keychain"
    echo "  list                   - List all stored MCP keys"
    echo "  export                 - Export all keys as environment variables"
    echo "  setup                  - Interactive setup for all services"
    echo ""
    echo "Services: github, brave, google-maps, slack-bot, slack-team, everart, postgres"
}

function set_key() {
    local service=$1
    local value=$2
    local keychain_service=$(get_keychain_service "$service")
    
    if [ -z "$keychain_service" ]; then
        echo -e "${RED}Error: Unknown service '$service'${NC}"
        return 1
    fi
    
    # Delete existing entry if it exists
    security delete-generic-password -s "$keychain_service" 2>/dev/null || true
    
    # Add new entry
    security add-generic-password -s "$keychain_service" -a "$USER" -w "$value" -T /usr/bin/security -U
    echo -e "${GREEN}✓ Stored $service API key in keychain${NC}"
}

function get_key() {
    local service=$1
    local keychain_service=$(get_keychain_service "$service")
    
    if [ -z "$keychain_service" ]; then
        echo -e "${RED}Error: Unknown service '$service'${NC}"
        return 1
    fi
    
    security find-generic-password -s "$keychain_service" -w 2>/dev/null || echo ""
}

function delete_key() {
    local service=$1
    local keychain_service=$(get_keychain_service "$service")
    
    if [ -z "$keychain_service" ]; then
        echo -e "${RED}Error: Unknown service '$service'${NC}"
        return 1
    fi
    
    if security delete-generic-password -s "$keychain_service" 2>/dev/null; then
        echo -e "${GREEN}✓ Deleted $service API key from keychain${NC}"
    else
        echo -e "${YELLOW}No key found for $service${NC}"
    fi
}

function list_keys() {
    echo -e "${BLUE}MCP API Keys in Keychain:${NC}"
    echo "------------------------"
    
    for service in $SERVICES; do
        local keychain_service=$(get_keychain_service "$service")
        if security find-generic-password -s "$keychain_service" 2>/dev/null >/dev/null; then
            echo -e "${GREEN}✓${NC} $service"
        else
            echo -e "${RED}✗${NC} $service"
        fi
    done
}

function export_keys() {
    echo "# MCP API Keys from Keychain"
    echo "# Source this file to set environment variables"
    echo ""
    
    # GitHub
    local github_token=$(get_key "github")
    [ -n "$github_token" ] && echo "export GITHUB_PERSONAL_ACCESS_TOKEN='$github_token'"
    
    # Brave
    local brave_key=$(get_key "brave")
    [ -n "$brave_key" ] && echo "export BRAVE_API_KEY='$brave_key'"
    
    # Google Maps
    local google_key=$(get_key "google-maps")
    [ -n "$google_key" ] && echo "export GOOGLE_MAPS_API_KEY='$google_key'"
    
    # Slack
    local slack_bot=$(get_key "slack-bot")
    [ -n "$slack_bot" ] && echo "export SLACK_BOT_TOKEN='$slack_bot'"
    
    local slack_team=$(get_key "slack-team")
    [ -n "$slack_team" ] && echo "export SLACK_TEAM_ID='$slack_team'"
    
    # Everart
    local everart_key=$(get_key "everart")
    [ -n "$everart_key" ] && echo "export EVERART_API_KEY='$everart_key'"
    
    # Postgres
    local postgres_conn=$(get_key "postgres")
    [ -n "$postgres_conn" ] && echo "export POSTGRES_CONNECTION_STRING='$postgres_conn'"
}

function interactive_setup() {
    echo -e "${BLUE}MCP API Key Setup${NC}"
    echo "=================="
    echo "Enter API keys for MCP services (press Enter to skip):"
    echo ""
    
    # GitHub
    echo -n "GitHub Personal Access Token: "
    read -s github_token
    echo ""
    [ -n "$github_token" ] && set_key "github" "$github_token"
    
    # Brave Search
    echo -n "Brave Search API Key: "
    read -s brave_key
    echo ""
    [ -n "$brave_key" ] && set_key "brave" "$brave_key"
    
    # Google Maps
    echo -n "Google Maps API Key: "
    read -s google_key
    echo ""
    [ -n "$google_key" ] && set_key "google-maps" "$google_key"
    
    # Slack Bot Token
    echo -n "Slack Bot Token: "
    read -s slack_bot
    echo ""
    [ -n "$slack_bot" ] && set_key "slack-bot" "$slack_bot"
    
    # Slack Team ID
    echo -n "Slack Team ID: "
    read slack_team
    echo ""
    [ -n "$slack_team" ] && set_key "slack-team" "$slack_team"
    
    # Everart
    echo -n "Everart API Key: "
    read -s everart_key
    echo ""
    [ -n "$everart_key" ] && set_key "everart" "$everart_key"
    
    # Postgres
    echo -n "Postgres Connection String: "
    read -s postgres_conn
    echo ""
    [ -n "$postgres_conn" ] && set_key "postgres" "$postgres_conn"
    
    echo ""
    echo -e "${GREEN}Setup complete!${NC}"
    echo ""
    list_keys
}

# Main command handling
case "$1" in
    set)
        if [ $# -ne 3 ]; then
            echo -e "${RED}Error: 'set' requires service and value${NC}"
            show_usage
            exit 1
        fi
        set_key "$2" "$3"
        ;;
    get)
        if [ $# -ne 2 ]; then
            echo -e "${RED}Error: 'get' requires service name${NC}"
            show_usage
            exit 1
        fi
        result=$(get_key "$2")
        if [ -n "$result" ]; then
            echo "$result"
        else
            echo -e "${YELLOW}No key found for $2${NC}"
            exit 1
        fi
        ;;
    delete)
        if [ $# -ne 2 ]; then
            echo -e "${RED}Error: 'delete' requires service name${NC}"
            show_usage
            exit 1
        fi
        delete_key "$2"
        ;;
    list)
        list_keys
        ;;
    export)
        export_keys
        ;;
    setup)
        interactive_setup
        ;;
    *)
        show_usage
        exit 1
        ;;
esac