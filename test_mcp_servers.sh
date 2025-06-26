#!/bin/bash

echo "Testing MCP Server Availability"
echo "==============================="
echo ""

# Real MCP servers found via npm search
REAL_SERVERS=(
    "@modelcontextprotocol/server-filesystem"
    "@modelcontextprotocol/server-github" 
    "@modelcontextprotocol/server-postgres"
    "@modelcontextprotocol/server-brave-search"
    "@modelcontextprotocol/server-memory"
    "@modelcontextprotocol/server-puppeteer"
    "@modelcontextprotocol/server-google-maps"
    "@modelcontextprotocol/server-everything"
    "@modelcontextprotocol/server-slack"
    "@modelcontextprotocol/server-everart"
    "@modelcontextprotocol/server-sequential-thinking"
    "@modelcontextprotocol/server-redis"
    "@anythingllm/mcp-server-macos-screencapture"
)

# Other potential servers
OTHER_SERVERS=(
    "@modelcontextprotocol/server-git"
    "@modelcontextprotocol/server-sqlite"
    "@modelcontextprotocol/server-fetch"
    "mcp-server-kubernetes"
)

echo "Checking Real MCP Servers:"
echo "--------------------------"
for server in "${REAL_SERVERS[@]}"; do
    if npm list -g "$server" &>/dev/null || npm view "$server" &>/dev/null; then
        echo "✅ $server - Available"
    else
        echo "❌ $server - Not found"
    fi
done

echo ""
echo "Checking Other Potential Servers:"
echo "---------------------------------"
for server in "${OTHER_SERVERS[@]}"; do
    if npm list -g "$server" &>/dev/null || npm view "$server" &>/dev/null; then
        echo "✅ $server - Available"
    else
        echo "❌ $server - Not found"
    fi
done

echo ""
echo "MCP Server Configuration Status:"
echo "--------------------------------"
echo "• Servers are configured in .mcp.json"
echo "• To use MCP servers, start a new Claude session"
echo "• The servers will be available as tools in the new session"
echo "• Some servers require API keys to function properly"
echo ""
echo "Note: Many servers listed in the configuration don't exist yet."
echo "The MCP ecosystem is still growing, and new servers are being added."