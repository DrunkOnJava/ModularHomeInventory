# MCP (Model Context Protocol) Servers Configuration

This project has 48 MCP servers configured to enhance development capabilities. Below is a comprehensive list of all configured servers and their purposes.

## Authentication Note
Many services can use credentials from the Apple Keychain. When authentication is needed, the system will first check the keychain for stored credentials.

## Core Development Servers

### 1. **filesystem**
- Enhanced file system operations within the project directory
- Path: `/Users/griffin/Projects/ModularHomeInventory`

### 2. **git**
- Git version control operations
- Enables advanced git workflows

### 3. **github**
- GitHub API integration
- Requires: `GITHUB_PERSONAL_ACCESS_TOKEN`

### 4. **memory**
- Persistent memory across Claude sessions
- Useful for maintaining context

### 5. **sequential-thinking**
- Complex reasoning and problem-solving capabilities
- Helps with architectural decisions

## Web & Automation

### 6. **brave-search**
- Web search capabilities
- Requires: `BRAVE_API_KEY`

### 7. **puppeteer**
- Browser automation and testing
- Useful for UI testing

### 8. **fetch**
- HTTP request handling
- API testing and integration

### 9. **time**
- Time and date operations
- Scheduling and time-based features

### 10. **everything**
- Comprehensive file search
- Fast file discovery

## Database Servers

### 11. **sqlite**
- SQLite database operations
- Local database management

### 12. **postgres**
- PostgreSQL operations
- Requires: `POSTGRES_CONNECTION_STRING`

### 13. **mongodb**
- NoSQL database operations
- Default: `mongodb://localhost:27017`

### 14. **redis**
- In-memory data store
- Default: `redis://localhost:6379`

### 15. **elasticsearch**
- Full-text search engine
- Default: `http://localhost:9200`

## Cloud Services

### 16. **aws**
- AWS services integration
- Requires: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`

### 17. **firebase**
- Firebase backend services
- Requires: `FIREBASE_PROJECT_ID`, etc.

### 18. **supabase**
- Open-source Firebase alternative
- Requires: `SUPABASE_URL`, `SUPABASE_ANON_KEY`

### 19. **cloudflare**
- CDN and edge computing
- Requires: `CLOUDFLARE_API_TOKEN`

### 20. **vercel**
- Deployment platform
- Requires: `VERCEL_TOKEN`

## Communication & Email

### 21. **gmail**
- Gmail integration (perfect for receipt scanning feature!)
- Requires: Google OAuth credentials

### 22. **sendgrid**
- Transactional email
- Requires: `SENDGRID_API_KEY`

### 23. **twilio**
- SMS, voice, and video
- Requires: `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`

## Payment & Finance

### 24. **stripe**
- Payment processing
- Requires: `STRIPE_API_KEY`

### 25. **plaid**
- Banking API integration
- Requires: `PLAID_CLIENT_ID`, `PLAID_SECRET`

### 26. **shopify**
- E-commerce platform
- Requires: `SHOPIFY_STORE_DOMAIN`, `SHOPIFY_ACCESS_TOKEN`

## Analytics & Monitoring

### 27. **mixpanel**
- Product analytics
- Requires: `MIXPANEL_TOKEN`

### 28. **segment**
- Customer data platform
- Requires: `SEGMENT_WRITE_KEY`

### 29. **datadog**
- Infrastructure monitoring
- Requires: `DATADOG_API_KEY`

### 30. **sentry**
- Error tracking
- Requires: `SENTRY_AUTH_TOKEN`

## Authentication & Identity

### 31. **auth0**
- Authentication service
- Requires: `AUTH0_DOMAIN`, credentials

### 32. **okta**
- Identity management
- Requires: `OKTA_DOMAIN`, `OKTA_API_TOKEN`

## Project Management & Design

### 33. **jira**
- Issue tracking
- Requires: `JIRA_HOST`, credentials

### 34. **linear**
- Modern issue tracking
- Requires: `LINEAR_API_KEY`

### 35. **figma**
- Design collaboration
- Requires: `FIGMA_ACCESS_TOKEN`

### 36. **notion**
- Documentation and wikis
- Requires: `NOTION_API_KEY`

## Google Services

### 37. **google-maps**
- Maps and location services
- Requires: `GOOGLE_MAPS_API_KEY`

### 38. **gdrive**
- Google Drive integration
- Requires: Google OAuth

### 39. **youtube**
- YouTube API access
- Requires: `YOUTUBE_API_KEY`

## macOS Specific

### 40. **apple-scripts**
- macOS automation via AppleScript
- System-level automation

### 41. **xcode**
- Xcode/macOS screen capture
- Development assistance

### 42. **raycast**
- macOS productivity launcher
- Quick actions

## AI & Machine Learning

### 43. **anthropic**
- Claude API integration
- Requires: `ANTHROPIC_API_KEY`

### 44. **openai**
- OpenAI GPT models
- Requires: `OPENAI_API_KEY`

## Search & Discovery

### 45. **algolia**
- Hosted search API
- Requires: `ALGOLIA_APP_ID`, `ALGOLIA_API_KEY`

## Note-Taking & Documentation

### 46. **obsidian**
- Knowledge management
- Requires: `OBSIDIAN_VAULT_PATH`

## Workflow Automation

### 47. **zapier**
- Workflow automation
- Requires: `ZAPIER_NLA_API_KEY`

### 48. **airtable**
- Spreadsheet database
- Requires: `AIRTABLE_API_KEY`

## Docker

### 49. **docker**
- Container management
- Default: `unix:///var/run/docker.sock`

## Configuration

All servers are configured in `.mcp.json`. To add credentials:

1. Edit `.mcp.json` and add your API keys/tokens
2. Or use environment variables
3. Many services will check Apple Keychain for stored credentials

## Usage

These servers provide Claude with enhanced capabilities for:
- File system operations
- Database queries
- API integrations
- Cloud service management
- Project management
- Design collaboration
- Payment processing
- Analytics tracking
- And much more!

## Security Notes

- Never commit API keys to version control
- Use environment variables or secure credential storage
- The `.mcp.json` file should be in `.gitignore` if it contains sensitive data
- Apple Keychain integration provides secure credential storage for macOS