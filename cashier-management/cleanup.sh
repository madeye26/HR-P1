#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LOGS_DIR="./logs/cleanup"
BACKUP_DIR="./backups/cleanup"
TEMP_DIR="./temp/cleanup"

# Create directories
mkdir -p "$LOGS_DIR" "$BACKUP_DIR" "$TEMP_DIR"

# Function to clean build artifacts
clean_builds() {
    echo -e "${BLUE}Cleaning build artifacts...${NC}"
    
    # Remove build directories
    rm -rf dist/
    rm -rf build/
    rm -rf .next/
    rm -rf .cache/
    rm -rf .parcel-cache/
    
    # Remove coverage reports
    rm -rf coverage/
    rm -rf .nyc_output/
    
    # Remove TypeScript build info
    rm -f tsconfig.tsbuildinfo
    
    echo -e "${GREEN}Build artifacts cleaned${NC}"
    
    # Log action
    log_action "clean" "builds" "Cleaned build artifacts"
}

# Function to clean dependencies
clean_dependencies() {
    echo -e "${BLUE}Cleaning dependencies...${NC}"
    
    # Backup package files
    cp package.json "$BACKUP_DIR/package.json.bak"
    [ -f package-lock.json ] && cp package-lock.json "$BACKUP_DIR/package-lock.json.bak"
    [ -f yarn.lock ] && cp yarn.lock "$BACKUP_DIR/yarn.lock.bak"
    
    # Remove dependencies
    rm -rf node_modules/
    rm -f package-lock.json
    rm -f yarn.lock
    
    # Clean npm cache
    npm cache clean --force
    
    echo -e "${GREEN}Dependencies cleaned${NC}"
    
    # Log action
    log_action "clean" "dependencies" "Cleaned dependencies"
}

# Function to clean logs
clean_logs() {
    echo -e "${BLUE}Cleaning logs...${NC}"
    
    # Archive old logs
    local archive_dir="$BACKUP_DIR/logs_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$archive_dir"
    
    # Move logs older than 30 days to archive
    find ./logs -type f -name "*.log" -mtime +30 -exec mv {} "$archive_dir/" \;
    
    # Compress archive
    tar -czf "$archive_dir.tar.gz" -C "$BACKUP_DIR" "$(basename "$archive_dir")"
    rm -rf "$archive_dir"
    
    # Clean empty log files
    find ./logs -type f -empty -delete
    
    echo -e "${GREEN}Logs cleaned${NC}"
    
    # Log action
    log_action "clean" "logs" "Cleaned and archived logs"
}

# Function to clean temporary files
clean_temp() {
    echo -e "${BLUE}Cleaning temporary files...${NC}"
    
    # Clean temp directories
    rm -rf "$TEMP_DIR"/*
    rm -rf ./temp/*
    
    # Clean editor files
    find . -type f -name "*.swp" -delete
    find . -type f -name "*~" -delete
    find . -type f -name ".DS_Store" -delete
    
    echo -e "${GREEN}Temporary files cleaned${NC}"
    
    # Log action
    log_action "clean" "temp" "Cleaned temporary files"
}

# Function to clean database
clean_database() {
    echo -e "${BLUE}Cleaning database...${NC}"
    
    read -p "This will clean database files. Are you sure? (y/n): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        # Backup database files
        local backup_file="$BACKUP_DIR/db_$(date +%Y%m%d_%H%M%S).tar.gz"
        tar -czf "$backup_file" ./data/db/
        
        # Clean database files
        rm -rf ./data/db/*
        
        echo -e "${GREEN}Database cleaned${NC}"
        
        # Log action
        log_action "clean" "database" "Cleaned database files"
    else
        echo -e "${YELLOW}Database cleanup cancelled${NC}"
    fi
}

# Function to clean Docker
clean_docker() {
    echo -e "${BLUE}Cleaning Docker...${NC}"
    
    # Stop all containers
    docker-compose down
    
    # Remove unused containers
    docker container prune -f
    
    # Remove unused images
    docker image prune -f
    
    # Remove unused volumes
    docker volume prune -f
    
    # Remove unused networks
    docker network prune -f
    
    echo -e "${GREEN}Docker cleaned${NC}"
    
    # Log action
    log_action "clean" "docker" "Cleaned Docker resources"
}

# Function to clean git
clean_git() {
    echo -e "${BLUE}Cleaning Git...${NC}"
    
    # Clean untracked files
    git clean -n
    read -p "Above files will be removed. Continue? (y/n): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        git clean -fd
        
        # Remove merged branches
        git branch --merged | grep -v "\*" | xargs -n 1 git branch -d
        
        # Prune remote branches
        git remote prune origin
        
        # Clean reflog
        git reflog expire --expire=now --all
        git gc --prune=now --aggressive
        
        echo -e "${GREEN}Git cleaned${NC}"
        
        # Log action
        log_action "clean" "git" "Cleaned Git repository"
    else
        echo -e "${YELLOW}Git cleanup cancelled${NC}"
    fi
}

# Function to clean backups
clean_backups() {
    echo -e "${BLUE}Cleaning old backups...${NC}"
    
    # Remove backups older than 90 days
    find "$BACKUP_DIR" -type f -name "*.tar.gz" -mtime +90 -delete
    
    # Clean empty backup directories
    find "$BACKUP_DIR" -type d -empty -delete
    
    echo -e "${GREEN}Old backups cleaned${NC}"
    
    # Log action
    log_action "clean" "backups" "Cleaned old backups"
}

# Function to clean all
clean_all() {
    echo -e "${BLUE}Cleaning everything...${NC}"
    
    read -p "This will clean all project files. Are you sure? (y/n): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        clean_builds
        clean_dependencies
        clean_logs
        clean_temp
        clean_database
        clean_docker
        clean_git
        clean_backups
        
        echo -e "${GREEN}All cleaning tasks completed${NC}"
        
        # Log action
        log_action "clean" "all" "Completed full cleanup"
    else
        echo -e "${YELLOW}Full cleanup cancelled${NC}"
    fi
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/cleanup_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Cleanup Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Clean Build Artifacts"
    echo -e "${YELLOW}2.${NC} Clean Dependencies"
    echo -e "${YELLOW}3.${NC} Clean Logs"
    echo -e "${YELLOW}4.${NC} Clean Temporary Files"
    echo -e "${YELLOW}5.${NC} Clean Database"
    echo -e "${YELLOW}6.${NC} Clean Docker"
    echo -e "${YELLOW}7.${NC} Clean Git"
    echo -e "${YELLOW}8.${NC} Clean Backups"
    echo -e "${YELLOW}9.${NC} Clean All"
    echo -e "${YELLOW}10.${NC} View Cleanup Logs"
    echo -e "${YELLOW}0.${NC} Exit"
    echo "------------------------"
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (0-10): " choice
    
    case $choice in
        1)
            clean_builds
            ;;
        2)
            clean_dependencies
            ;;
        3)
            clean_logs
            ;;
        4)
            clean_temp
            ;;
        5)
            clean_database
            ;;
        6)
            clean_docker
            ;;
        7)
            clean_git
            ;;
        8)
            clean_backups
            ;;
        9)
            clean_all
            ;;
        10)
            if [ -f "$LOGS_DIR/cleanup_actions.log" ]; then
                less "$LOGS_DIR/cleanup_actions.log"
            else
                echo -e "${YELLOW}No cleanup logs found${NC}"
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
