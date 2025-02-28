#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LOGS_DIR="./logs/dev"
TEMP_DIR="./temp/dev"

# Create directories
mkdir -p "$LOGS_DIR" "$TEMP_DIR"

# Function to start development server
start_dev() {
    echo -e "${BLUE}Starting development server...${NC}"
    
    # Check if server is already running
    if [ -f "$TEMP_DIR/dev.pid" ]; then
        echo -e "${YELLOW}Development server already running${NC}"
        return 1
    fi
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        echo -e "${YELLOW}Installing dependencies...${NC}"
        npm install
    fi
    
    # Start development server
    npm run dev > "$LOGS_DIR/dev.log" 2>&1 &
    echo $! > "$TEMP_DIR/dev.pid"
    
    echo -e "${GREEN}Development server started${NC}"
    echo -e "Logs available at: $LOGS_DIR/dev.log"
    
    # Log action
    log_action "start_dev" "server" "Started development server"
}

# Function to stop development server
stop_dev() {
    echo -e "${BLUE}Stopping development server...${NC}"
    
    if [ -f "$TEMP_DIR/dev.pid" ]; then
        kill $(cat "$TEMP_DIR/dev.pid")
        rm "$TEMP_DIR/dev.pid"
        echo -e "${GREEN}Development server stopped${NC}"
        
        # Log action
        log_action "stop_dev" "server" "Stopped development server"
    else
        echo -e "${YELLOW}No development server running${NC}"
    fi
}

# Function to run tests
run_tests() {
    echo -e "${BLUE}Running tests...${NC}"
    
    echo "Select test type:"
    echo "1. All Tests"
    echo "2. Unit Tests"
    echo "3. Integration Tests"
    echo "4. E2E Tests"
    read -p "Enter choice (1-4): " choice
    
    case $choice in
        1)
            npm test
            ;;
        2)
            npm run test:unit
            ;;
        3)
            npm run test:integration
            ;;
        4)
            npm run test:e2e
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            return 1
            ;;
    esac
    
    # Log action
    log_action "run_tests" "tests" "Ran tests"
}

# Function to run linting
run_lint() {
    echo -e "${BLUE}Running linting...${NC}"
    
    echo "Select scope:"
    echo "1. All Files"
    echo "2. Changed Files"
    echo "3. Specific Directory"
    read -p "Enter choice (1-3): " choice
    
    case $choice in
        1)
            npm run lint
            ;;
        2)
            git diff --name-only | grep '\.[jt]sx\?$' | xargs npm run lint --
            ;;
        3)
            read -p "Enter directory path: " dir
            npm run lint "$dir"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            return 1
            ;;
    esac
    
    # Log action
    log_action "run_lint" "lint" "Ran linting"
}

# Function to build project
build_project() {
    echo -e "${BLUE}Building project...${NC}"
    
    # Clean build directory
    rm -rf dist
    
    # Run build
    if npm run build; then
        echo -e "${GREEN}Build completed successfully${NC}"
        
        # Log action
        log_action "build" "project" "Built project"
    else
        echo -e "${RED}Build failed${NC}"
        return 1
    fi
}

# Function to generate types
generate_types() {
    echo -e "${BLUE}Generating TypeScript types...${NC}"
    
    # Run type generation
    if npm run generate:types; then
        echo -e "${GREEN}Types generated successfully${NC}"
        
        # Log action
        log_action "generate" "types" "Generated TypeScript types"
    else
        echo -e "${RED}Type generation failed${NC}"
        return 1
    fi
}

# Function to analyze bundle
analyze_bundle() {
    echo -e "${BLUE}Analyzing bundle...${NC}"
    
    # Build with source maps
    GENERATE_SOURCEMAP=true npm run build
    
    # Run bundle analyzer
    npm run analyze
    
    # Log action
    log_action "analyze" "bundle" "Analyzed bundle"
}

# Function to run development tools
run_tools() {
    echo -e "${BLUE}Development Tools${NC}"
    
    echo "Select tool:"
    echo "1. TypeScript Type Checker (tsc)"
    echo "2. ESLint Fix"
    echo "3. Prettier Format"
    echo "4. Update Dependencies"
    read -p "Enter choice (1-4): " choice
    
    case $choice in
        1)
            npx tsc --noEmit
            ;;
        2)
            npm run lint:fix
            ;;
        3)
            npm run format
            ;;
        4)
            npm update
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            return 1
            ;;
    esac
    
    # Log action
    log_action "run_tools" "tools" "Ran development tools"
}

# Function to clean project
clean_project() {
    echo -e "${BLUE}Cleaning project...${NC}"
    
    # Clean build artifacts
    rm -rf dist
    
    # Clean cache
    rm -rf .cache
    
    # Clean test coverage
    rm -rf coverage
    
    # Clean dependencies
    read -p "Clean node_modules? (y/n): " clean_modules
    if [[ $clean_modules =~ ^[Yy]$ ]]; then
        rm -rf node_modules
        rm -f package-lock.json
    fi
    
    echo -e "${GREEN}Project cleaned${NC}"
    
    # Log action
    log_action "clean" "project" "Cleaned project"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/dev_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Development Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Start Development Server"
    echo -e "${YELLOW}2.${NC} Stop Development Server"
    echo -e "${YELLOW}3.${NC} Run Tests"
    echo -e "${YELLOW}4.${NC} Run Linting"
    echo -e "${YELLOW}5.${NC} Build Project"
    echo -e "${YELLOW}6.${NC} Generate Types"
    echo -e "${YELLOW}7.${NC} Analyze Bundle"
    echo -e "${YELLOW}8.${NC} Development Tools"
    echo -e "${YELLOW}9.${NC} Clean Project"
    echo -e "${YELLOW}10.${NC} View Logs"
    echo -e "${YELLOW}0.${NC} Exit"
    echo "------------------------"
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (0-10): " choice
    
    case $choice in
        1)
            start_dev
            ;;
        2)
            stop_dev
            ;;
        3)
            run_tests
            ;;
        4)
            run_lint
            ;;
        5)
            build_project
            ;;
        6)
            generate_types
            ;;
        7)
            analyze_bundle
            ;;
        8)
            run_tools
            ;;
        9)
            clean_project
            ;;
        10)
            if [ -f "$LOGS_DIR/dev_actions.log" ]; then
                less "$LOGS_DIR/dev_actions.log"
            else
                echo -e "${YELLOW}No development logs found${NC}"
            fi
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
