#!/bin/bash

# Check for hardcoded secrets and sensitive information

echo "🔍 Checking for hardcoded secrets..."

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Exit code
EXIT_CODE=0

# Patterns to check
declare -a PATTERNS=(
    # API Keys
    "api[_-]?key.*=.*['\"].*['\"]"
    "apikey.*=.*['\"].*['\"]"
    
    # AWS
    "AKIA[0-9A-Z]{16}"
    "aws[_-]?access[_-]?key"
    "aws[_-]?secret"
    
    # Generic secrets
    "password.*=.*['\"].*['\"]"
    "passwd.*=.*['\"].*['\"]"
    "pwd.*=.*['\"].*['\"]"
    "secret.*=.*['\"].*['\"]"
    "token.*=.*['\"].*['\"]"
    
    # Private keys
    "-----BEGIN.*PRIVATE KEY-----"
    "-----BEGIN RSA PRIVATE KEY-----"
    "-----BEGIN EC PRIVATE KEY-----"
    
    # Connection strings
    "mongodb\+srv:\/\/"
    "postgres:\/\/.*:.*@"
    "mysql:\/\/.*:.*@"
    
    # OAuth
    "client[_-]?secret.*=.*['\"].*['\"]"
    "client[_-]?id.*=.*['\"].*['\"]"
    
    # Stripe
    "sk_live_[0-9a-zA-Z]{24}"
    "sk_test_[0-9a-zA-Z]{24}"
    
    # GitHub
    "ghp_[0-9a-zA-Z]{36}"
    "ghs_[0-9a-zA-Z]{36}"
    
    # Slack
    "xox[baprs]-[0-9a-zA-Z]{10,48}"
)

# Files to exclude
EXCLUDE_DIRS="-path ./DerivedData -prune -o -path ./.build -prune -o -path ./Pods -prune -o"

# Check each pattern
for pattern in "${PATTERNS[@]}"; do
    echo -n "Checking for: $pattern ... "
    
    # Use grep to find matches
    matches=$(find . $EXCLUDE_DIRS -type f \( -name "*.swift" -o -name "*.h" -o -name "*.m" \) -print0 | xargs -0 grep -i -E "$pattern" 2>/dev/null || true)
    
    if [ -n "$matches" ]; then
        echo -e "${RED}FOUND${NC}"
        echo "$matches" | while read -r line; do
            echo -e "${YELLOW}  $line${NC}"
        done
        EXIT_CODE=1
    else
        echo -e "${GREEN}OK${NC}"
    fi
done

# Check for specific files that shouldn't exist
echo -e "\n🔍 Checking for sensitive files..."

declare -a SENSITIVE_FILES=(
    ".env"
    "secrets.json"
    "credentials.json"
    "*.pem"
    "*.key"
    "*.p12"
    "*.pfx"
)

for file_pattern in "${SENSITIVE_FILES[@]}"; do
    echo -n "Checking for: $file_pattern ... "
    
    files=$(find . $EXCLUDE_DIRS -name "$file_pattern" -type f 2>/dev/null || true)
    
    if [ -n "$files" ]; then
        echo -e "${RED}FOUND${NC}"
        echo "$files" | while read -r file; do
            echo -e "${YELLOW}  $file${NC}"
        done
        EXIT_CODE=1
    else
        echo -e "${GREEN}OK${NC}"
    fi
done

# Check Info.plist for sensitive data
echo -e "\n🔍 Checking Info.plist files..."

info_plists=$(find . $EXCLUDE_DIRS -name "Info.plist" -type f 2>/dev/null || true)

for plist in $info_plists; do
    echo -n "Checking: $plist ... "
    
    # Check for common sensitive keys
    sensitive_keys=$(plutil -convert json -o - "$plist" 2>/dev/null | jq -r 'keys[] | select(test("api|key|secret|token|password"; "i"))' 2>/dev/null || true)
    
    if [ -n "$sensitive_keys" ]; then
        echo -e "${RED}Sensitive keys found${NC}"
        echo "$sensitive_keys" | while read -r key; do
            echo -e "${YELLOW}  $key${NC}"
        done
        EXIT_CODE=1
    else
        echo -e "${GREEN}OK${NC}"
    fi
done

# Summary
echo -e "\n📊 Summary:"
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ No secrets detected!${NC}"
else
    echo -e "${RED}❌ Potential secrets found! Please review and remove them.${NC}"
    echo -e "\nRecommendations:"
    echo "1. Use environment variables for configuration"
    echo "2. Store secrets in Keychain or secure services"
    echo "3. Use .gitignore to exclude sensitive files"
    echo "4. Consider using tools like git-secrets or gitleaks"
fi

exit $EXIT_CODE