#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEPLOY_DIR="./deploy"
LOGS_DIR="./logs/deploy"
BACKUP_DIR="./backups/deploy"
TEMP_DIR="./temp/deploy"

# Environment configurations
ENVIRONMENTS=(
    "development"
    "staging"
    "production"
)

# Create directories
mkdir -p "$DEPLOY_DIR" "$LOGS_DIR" "$BACKUP_DIR" "$TEMP_DIR"

# Function to validate deployment
validate_deployment() {
    echo -e "${BLUE}Validating deployment...${NC}"
    
    local issues=0
    
    # Check required files
    local required_files=(
        "package.json"
        "tsconfig.json"
        "vite.config.ts"
        ".env"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            echo -e "${RED}Missing required file: $file${NC}"
            ((issues++))
        fi
    done
    
    # Check git status
    if [ -n "$(git status --porcelain)" ]; then
        echo -e "${YELLOW}Warning: You have uncommitted changes${NC}"
        ((issues++))
    fi
    
    # Check dependencies
    if ! npm ls --prod > /dev/null 2>&1; then
        echo -e "${RED}Dependency check failed${NC}"
        ((issues++))
    fi
    
    # Run tests
    if ! npm test > /dev/null 2>&1; then
        echo -e "${RED}Tests failed${NC}"
        ((issues++))
    fi
    
    if [ $issues -eq 0 ]; then
        echo -e "${GREEN}Validation passed${NC}"
        return 0
    else
        echo -e "${RED}Validation failed with $issues issue(s)${NC}"
        return 1
    fi
}

# Function to build application
build_app() {
    local env=$1
    echo -e "${BLUE}Building application for $env...${NC}"
    
    # Set environment
    export NODE_ENV=$env
    
    # Clean build directory
    rm -rf dist
    
    # Install dependencies
    npm ci
    
    # Build application
    if npm run build; then
        echo -e "${GREEN}Build completed for $env${NC}"
        return 0
    else
        echo -e "${RED}Build failed for $env${NC}"
        return 1
    fi
}

# Function to deploy application
deploy_app() {
    local env=$1
    echo -e "${BLUE}Deploying to $env...${NC}"
    
    # Create deployment directory
    local deploy_path="$DEPLOY_DIR/$env"
    mkdir -p "$deploy_path"
    
    # Copy build files
    cp -r dist/* "$deploy_path/"
    
    # Copy configuration
    cp .env.$env "$deploy_path/.env"
    
    # Deploy based on environment
    case $env in
        "development")
            # Local deployment
            echo -e "${GREEN}Deployed to local environment${NC}"
            ;;
        "staging")
            # Deploy to staging server
            echo -e "${YELLOW}Deploying to staging server...${NC}"
            # Add your staging deployment commands here
            ;;
        "production")
            # Deploy to production server
            echo -e "${YELLOW}Deploying to production server...${NC}"
            # Add your production deployment commands here
            ;;
    esac
    
    echo -e "${GREEN}Deployment to $env completed${NC}"
    
    # Log action
    log_action "deploy" "$env" "Deployed application"
}

# Function to rollback deployment
rollback_deployment() {
    local env=$1
    echo -e "${BLUE}Rolling back $env deployment...${NC}"
    
    # Check for backup
    local latest_backup=$(ls -t "$BACKUP_DIR/$env"_* 2>/dev/null | head -1)
    
    if [ -z "$latest_backup" ]; then
        echo -e "${RED}No backup found for rollback${NC}"
        return 1
    fi
    
    # Restore from backup
    local deploy_path="$DEPLOY_DIR/$env"
    rm -rf "$deploy_path"
    tar -xzf "$latest_backup" -C "$DEPLOY_DIR"
    
    echo -e "${GREEN}Rollback completed for $env${NC}"
    
    # Log action
    log_action "rollback" "$env" "Rolled back deployment"
}

# Function to backup deployment
backup_deployment() {
    local env=$1
    echo -e "${BLUE}Backing up $env deployment...${NC}"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/${env}_${timestamp}.tar.gz"
    
    # Create backup
    tar -czf "$backup_file" -C "$DEPLOY_DIR" "$env"
    
    echo -e "${GREEN}Backup created: $backup_file${NC}"
    
    # Clean old backups (keep last 5)
    ls -t "$BACKUP_DIR/${env}_"* 2>/dev/null | tail -n +6 | xargs -r rm
    
    # Log action
    log_action "backup" "$env" "Created deployment backup"
}

# Function to monitor deployment
monitor_deployment() {
    local env=$1
    echo -e "${BLUE}Monitoring $env deployment...${NC}"
    
    # Check application status
    echo -e "\n${YELLOW}Application Status:${NC}"
    curl -s http://localhost:3000/health || echo "Application not responding"
    
    # Check server resources
    echo -e "\n${YELLOW}Server Resources:${NC}"
    df -h
    free -h
    
    # Check logs
    echo -e "\n${YELLOW}Recent Logs:${NC}"
    tail -n 50 "$LOGS_DIR/deploy_${env}.log"
    
    # Log action
    log_action "monitor" "$env" "Monitored deployment"
}

# Function to clean deployment
clean_deployment() {
    echo -e "${BLUE}Cleaning deployment artifacts...${NC}"
    
    # Clean temporary files
    rm -rf "$TEMP_DIR"/*
    
    # Clean old logs (keep last 30 days)
    find "$LOGS_DIR" -name "*.log" -mtime +30 -delete
    
    # Clean old backups (keep last 30 days)
    find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete
    
    echo -e "${GREEN}Deployment cleanup completed${NC}"
    
    # Log action
    log_action "clean" "all" "Cleaned deployment artifacts"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/deploy_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Deployment Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Validate Deployment"
    echo -e "${YELLOW}2.${NC} Deploy Application"
    echo -e "${YELLOW}3.${NC} Rollback Deployment"
    echo -e "${YELLOW}4.${NC} Backup Deployment"
    echo -e "${YELLOW}5.${NC} Monitor Deployment"
    echo -e "${YELLOW}6.${NC} Clean Deployment"
    echo -e "${YELLOW}7.${NC} View Logs"
    echo -e "${YELLOW}0.${NC} Exit"
    echo "------------------------"
}

# Function to select environment
select_environment() {
    echo -e "\n${BLUE}Select Environment:${NC}"
    for i in "${!ENVIRONMENTS[@]}"; do
        echo "$((i+1)). ${ENVIRONMENTS[$i]}"
    done
    
    read -p "Enter choice (1-${#ENVIRONMENTS[@]}): " choice
    
    if [ "$choice" -ge 1 ] && [ "$choice" -le "${#ENVIRONMENTS[@]}" ]; then
        echo "${ENVIRONMENTS[$((choice-1))]}"
    else
        echo ""
    fi
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (0-7): " choice
    
    case $choice in
        1)
            validate_deployment
            ;;
        2)
            env=$(select_environment)
            if [ -n "$env" ]; then
                if validate_deployment && build_app "$env"; then
                    deploy_app "$env"
                fi
            fi
            ;;
        3)
            env=$(select_environment)
            if [ -n "$env" ]; then
                rollback_deployment "$env"
            fi
            ;;
        4)
            env=$(select_environment)
            if [ -n "$env" ]; then
                backup_deployment "$env"
            fi
            ;;
        5)
            env=$(select_environment)
            if [ -n "$env" ]; then
                monitor_deployment "$env"
            fi
            ;;
        6)
            clean_deployment
            ;;
        7)
            if [ -f "$LOGS_DIR/deploy_actions.log" ]; then
                less "$LOGS_DIR/deploy_actions.log"
            else
                echo -e "${YELLOW}No deployment logs found${NC}"
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
