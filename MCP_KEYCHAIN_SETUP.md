# MCP Server Keychain Integration

This project uses macOS Keychain to securely store API keys for MCP servers.

## Quick Start

1. **Setup API Keys** (interactive):
   ```bash
   ./scripts/mcp_keychain_manager.sh setup
   ```

2. **Start Claude with Keychain**:
   ```bash
   ./scripts/claude_with_keychain.sh
   ```

## Manual Key Management

### Store a key:
```bash
./scripts/mcp_keychain_manager.sh set github YOUR_GITHUB_TOKEN
./scripts/mcp_keychain_manager.sh set brave YOUR_BRAVE_API_KEY
```

### Retrieve a key:
```bash
./scripts/mcp_keychain_manager.sh get github
```

### List all keys:
```bash
./scripts/mcp_keychain_manager.sh list
```

### Delete a key:
```bash
./scripts/mcp_keychain_manager.sh delete github
```

### Export all keys as environment variables:
```bash
./scripts/mcp_keychain_manager.sh export > mcp_env.sh
source mcp_env.sh
```

## Supported Services

- **github**: GitHub Personal Access Token
- **brave**: Brave Search API Key
- **google-maps**: Google Maps API Key
- **slack-bot**: Slack Bot Token
- **slack-team**: Slack Team ID
- **everart**: Everart API Key
- **postgres**: PostgreSQL Connection String

## How It Works

1. API keys are stored securely in macOS Keychain
2. The `claude_with_keychain.sh` script loads keys from Keychain
3. Keys are exported as environment variables
4. MCP servers read from these environment variables

## Security Benefits

- No API keys in plain text files
- Keys are encrypted by macOS
- Access requires user authentication
- Keys persist across sessions
- Easy to rotate/update keys

## Troubleshooting

If you get permission errors, you may need to grant Terminal access to your Keychain:
1. Open System Preferences → Security & Privacy → Privacy
2. Select "Full Disk Access" or "Files and Folders"
3. Add Terminal.app or your terminal emulator

## Redis Server Note

Redis server is configured to use `redis://localhost:6379` by default. 
Make sure Redis is running locally or update the connection string.