#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display status message
status_msg() {
    echo -e "${BLUE}$1${NC}"
}

# Function to display success message
success_msg() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to display error message
error_msg() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to create directory if it doesn't exist
create_dir() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
        success_msg "Created directory: $1"
    else
        status_msg "Directory already exists: $1"
    fi
}

# Make scripts executable
status_msg "\nMaking scripts executable..."
chmod +x *.sh
success_msg "Made scripts executable"

# Create project structure
status_msg "\nCreating project structure..."

# Create main directories
create_dir "src/components"
create_dir "src/context"
create_dir "src/styles"
create_dir "src/utils"
create_dir "src/types"
create_dir "src/assets"
create_dir "src/hooks"
create_dir "src/services"
create_dir "src/constants"
create_dir "public"

# Create empty .gitkeep files in empty directories
status_msg "\nCreating .gitkeep files..."
find . -type d -empty -exec touch {}/.gitkeep \;
success_msg "Created .gitkeep files"

# Create .gitignore if it doesn't exist
if [ ! -f ".gitignore" ]; then
    status_msg "\nCreating .gitignore..."
    cat > .gitignore << EOL
# Dependencies
node_modules
.pnp
.pnp.js

# Testing
coverage

# Production
dist
build

# Misc
.DS_Store
.env.local
.env.development.local
.env.test.local
.env.production.local
.env

# Logs
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Editor directories and files
.vscode/*
!.vscode/extensions.json
.idea
*.suo
*.ntvs*
*.njsproj
*.sln
*.sw?

# TypeScript
*.tsbuildinfo

# Backup files
backup
backup_*
*.backup
*.bak

# System files
Thumbs.db
EOL
    success_msg "Created .gitignore"
else
    status_msg ".gitignore already exists"
fi

# Create .env files
status_msg "\nCreating environment files..."
if [ ! -f ".env" ]; then
    echo "VITE_APP_TITLE=نظام إدارة الرواتب" > .env
    success_msg "Created .env"
fi

if [ ! -f ".env.example" ]; then
    echo "VITE_APP_TITLE=نظام إدارة الرواتب" > .env.example
    success_msg "Created .env.example"
fi

# Initialize Git if not already initialized
if [ ! -d ".git" ]; then
    status_msg "\nInitializing Git repository..."
    git init
    success_msg "Initialized Git repository"
else
    status_msg "\nGit repository already initialized"
fi

# Create initial Git commit if needed
if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
    status_msg "\nCreating initial commit..."
    git add .
    git commit -m "Initial commit: Project setup"
    success_msg "Created initial commit"
fi

# Install dependencies if package.json exists and node_modules doesn't
if [ -f "package.json" ] && [ ! -d "node_modules" ]; then
    status_msg "\nInstalling dependencies..."
    npm install
    success_msg "Installed dependencies"
fi

# Final message
echo -e "\n${GREEN}Setup completed successfully!${NC}"
echo -e "\nYou can now:"
echo -e "${YELLOW}1.${NC} Run './dev.sh' for development tasks"
echo -e "${YELLOW}2.${NC} Run './deploy.sh' for deployment tasks"
echo -e "${YELLOW}3.${NC} Run './migrate.sh' to migrate to TypeScript"
echo -e "${YELLOW}4.${NC} Run './test-migration.sh' to verify migration"

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo -e "\n${RED}Warning: npm is not installed. Please install Node.js and npm to proceed.${NC}"
fi

echo -e "\nHappy coding! 🚀\n"
