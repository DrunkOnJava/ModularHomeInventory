#!/bin/bash

# Auto-commit script for successful builds
# This script stages, commits, and pushes changes to GitHub

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if there are any changes to commit
if [[ -z $(git status -s) ]]; then
    echo -e "${YELLOW}No changes to commit${NC}"
    exit 0
fi

# Stage all changes
echo -e "${GREEN}Staging all changes...${NC}"
git add -A

# Get the status for the commit message
CHANGED_FILES=$(git diff --cached --name-only | wc -l | tr -d ' ')
INSERTIONS=$(git diff --cached --shortstat | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo "0")
DELETIONS=$(git diff --cached --shortstat | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+' || echo "0")

# Generate commit message based on changes
if [[ $CHANGED_FILES -eq 1 ]]; then
    FILE=$(git diff --cached --name-only)
    # Extract filename without path
    FILENAME=$(basename "$FILE")
    
    # Determine action based on git status
    if git status --porcelain | grep -q "^A.*$FILE"; then
        ACTION="Add"
    elif git status --porcelain | grep -q "^D.*$FILE"; then
        ACTION="Remove"
    else
        ACTION="Update"
    fi
    
    COMMIT_MSG="$ACTION $FILENAME"
else
    # Multiple files changed
    COMMIT_MSG="Update $CHANGED_FILES files (+$INSERTIONS -$DELETIONS)"
fi

# Add auto-commit footer
COMMIT_MSG="$COMMIT_MSG

🤖 Auto-committed after successful build

Co-Authored-By: Claude <noreply@anthropic.com>"

# Commit changes
echo -e "${GREEN}Committing changes...${NC}"
git commit -m "$COMMIT_MSG"

# Push to remote
echo -e "${GREEN}Pushing to GitHub...${NC}"
git push origin main

echo -e "${GREEN}✅ Successfully committed and pushed to GitHub!${NC}"