#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check dependencies
check_dependencies() {
    local missing=0
    echo -e "${BLUE}Checking dependencies...${NC}"
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        echo -e "${RED}✗ Node.js is not installed${NC}"
        missing=1
    else
        echo -e "${GREEN}✓ Node.js $(node --version)${NC}"
    fi
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}✗ npm is not installed${NC}"
        missing=1
    else
        echo -e "${GREEN}✓ npm $(npm --version)${NC}"
    fi
    
    # Check Git
    if ! command -v git &> /dev/null; then
        echo -e "${RED}✗ Git is not installed${NC}"
        missing=1
    else
        echo -e "${GREEN}✓ Git $(git --version)${NC}"
    fi
    
    return $missing
}

# Function to clean project
clean_project() {
    echo -e "${BLUE}Cleaning project...${NC}"
    
    # Remove build directories
    rm -rf dist build .cache
    
    # Remove dependencies
    rm -rf node_modules
    
    # Remove lock files
    rm -f package-lock.json yarn.lock pnpm-lock.yaml
    
    # Remove TypeScript cache
    rm -f tsconfig.tsbuildinfo
    
    # Remove test coverage
    rm -rf coverage
    
    # Remove environment files
    rm -f .env.local .env.development.local .env.test.local .env.production.local
    
    echo -e "${GREEN}Project cleaned successfully${NC}"
}

# Function to update dependencies
update_dependencies() {
    echo -e "${BLUE}Updating dependencies...${NC}"
    
    # Create backup of package.json
    cp package.json package.json.backup
    
    # Update dependencies
    npm update
    
    # Update dev dependencies
    npm update --save-dev
    
    echo -e "${GREEN}Dependencies updated successfully${NC}"
    echo -e "${YELLOW}Backup of package.json created as package.json.backup${NC}"
}

# Function to run security audit
security_audit() {
    echo -e "${BLUE}Running security audit...${NC}"
    
    # Run npm audit
    npm audit
    
    # Run npm outdated
    echo -e "\n${BLUE}Checking for outdated packages...${NC}"
    npm outdated
}

# Function to optimize images
optimize_images() {
    echo -e "${BLUE}Optimizing images...${NC}"
    
    # Check if imagemin-cli is installed
    if ! command -v imagemin &> /dev/null; then
        echo -e "${YELLOW}Installing imagemin-cli...${NC}"
        npm install -g imagemin-cli
    fi
    
    # Optimize PNG files
    find src/assets -name "*.png" -exec imagemin {} --out-dir=src/assets/optimized \;
    
    # Optimize JPG files
    find src/assets -name "*.jpg" -exec imagemin {} --out-dir=src/assets/optimized \;
    
    echo -e "${GREEN}Images optimized successfully${NC}"
}

# Function to analyze bundle size
analyze_bundle() {
    echo -e "${BLUE}Analyzing bundle size...${NC}"
    
    # Build project with source maps
    npm run build
    
    # Install source-map-explorer if not present
    if ! command -v source-map-explorer &> /dev/null; then
        npm install -g source-map-explorer
    fi
    
    # Analyze bundle
    source-map-explorer 'dist/assets/*.js'
}

# Function to check code quality
check_code_quality() {
    echo -e "${BLUE}Checking code quality...${NC}"
    
    # Run ESLint
    echo -e "\n${BLUE}Running ESLint...${NC}"
    npm run lint
    
    # Run TypeScript compiler
    echo -e "\n${BLUE}Running TypeScript compiler...${NC}"
    npx tsc --noEmit
    
    # Run Prettier
    echo -e "\n${BLUE}Checking code formatting...${NC}"
    npx prettier --check "src/**/*.{ts,tsx}"
}

# Function to generate documentation
generate_docs() {
    echo -e "${BLUE}Generating documentation...${NC}"
    
    # Install TypeDoc if not present
    if ! command -v typedoc &> /dev/null; then
        npm install -g typedoc
    fi
    
    # Generate documentation
    typedoc --out docs src
    
    echo -e "${GREEN}Documentation generated in docs directory${NC}"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Development Tools Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Check dependencies"
    echo -e "${YELLOW}2.${NC} Clean project"
    echo -e "${YELLOW}3.${NC} Update dependencies"
    echo -e "${YELLOW}4.${NC} Run security audit"
    echo -e "${YELLOW}5.${NC} Optimize images"
    echo -e "${YELLOW}6.${NC} Analyze bundle size"
    echo -e "${YELLOW}7.${NC} Check code quality"
    echo -e "${YELLOW}8.${NC} Generate documentation"
    echo -e "${YELLOW}9.${NC} Run all checks"
    echo -e "${YELLOW}0.${NC} Exit"
    echo "------------------------"
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (0-9): " choice
    
    case $choice in
        1)
            check_dependencies
            ;;
        2)
            clean_project
            ;;
        3)
            update_dependencies
            ;;
        4)
            security_audit
            ;;
        5)
            optimize_images
            ;;
        6)
            analyze_bundle
            ;;
        7)
            check_code_quality
            ;;
        8)
            generate_docs
            ;;
        9)
            check_dependencies
            check_code_quality
            security_audit
            analyze_bundle
            ;;
        0)
            echo -e "\n${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${RED}Invalid option${NC}"
            sleep 1
            ;;
    esac
    
    echo -e "\nPress Enter to continue..."
    read
done
