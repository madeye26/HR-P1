#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCKER_DIR="./docker"
COMPOSE_FILE="$DOCKER_DIR/docker-compose.yml"
ENV_FILE="$DOCKER_DIR/.env"
LOGS_DIR="./logs/docker"

# Create directories
mkdir -p "$DOCKER_DIR" "$LOGS_DIR"

# Create docker-compose.yml if it doesn't exist
if [ ! -f "$COMPOSE_FILE" ]; then
    cat > "$COMPOSE_FILE" << EOL
version: '3.8'

services:
  app:
    build:
      context: ..
      dockerfile: docker/Dockerfile
    ports:
      - "3000:3000"
    volumes:
      - ../:/app
      - /app/node_modules
    environment:
      - NODE_ENV=\${NODE_ENV:-development}
    depends_on:
      - db
      - redis

  db:
    image: postgres:13-alpine
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=\${DB_NAME:-cashier_management}
      - POSTGRES_USER=\${DB_USER:-admin}
      - POSTGRES_PASSWORD=\${DB_PASSWORD:-secret}

  redis:
    image: redis:6-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
EOL
fi

# Create Dockerfile if it doesn't exist
if [ ! -f "$DOCKER_DIR/Dockerfile" ]; then
    cat > "$DOCKER_DIR/Dockerfile" << EOL
FROM node:16-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build

EXPOSE 3000

CMD ["npm", "start"]
EOL
fi

# Create .env file if it doesn't exist
if [ ! -f "$ENV_FILE" ]; then
    cat > "$ENV_FILE" << EOL
NODE_ENV=development
DB_NAME=cashier_management
DB_USER=admin
DB_PASSWORD=secret
EOL
fi

# Function to start containers
start_containers() {
    echo -e "${BLUE}Starting containers...${NC}"
    
    if docker-compose -f "$COMPOSE_FILE" up -d; then
        echo -e "${GREEN}Containers started successfully${NC}"
        
        # Log action
        log_action "start" "all" "Started containers"
    else
        echo -e "${RED}Failed to start containers${NC}"
        return 1
    fi
}

# Function to stop containers
stop_containers() {
    echo -e "${BLUE}Stopping containers...${NC}"
    
    if docker-compose -f "$COMPOSE_FILE" down; then
        echo -e "${GREEN}Containers stopped successfully${NC}"
        
        # Log action
        log_action "stop" "all" "Stopped containers"
    else
        echo -e "${RED}Failed to stop containers${NC}"
        return 1
    fi
}

# Function to show container status
show_status() {
    echo -e "${BLUE}Container Status${NC}"
    echo "------------------------"
    
    docker-compose -f "$COMPOSE_FILE" ps
    
    echo -e "\n${BLUE}Resource Usage${NC}"
    echo "------------------------"
    
    docker stats --no-stream
}

# Function to view container logs
view_logs() {
    echo -e "${BLUE}Container Logs${NC}"
    
    echo "Select container:"
    echo "1. App"
    echo "2. Database"
    echo "3. Redis"
    read -p "Enter choice (1-3): " choice
    
    case $choice in
        1)
            docker-compose -f "$COMPOSE_FILE" logs app
            ;;
        2)
            docker-compose -f "$COMPOSE_FILE" logs db
            ;;
        3)
            docker-compose -f "$COMPOSE_FILE" logs redis
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            return 1
            ;;
    esac
}

# Function to rebuild containers
rebuild_containers() {
    echo -e "${BLUE}Rebuilding containers...${NC}"
    
    if docker-compose -f "$COMPOSE_FILE" up -d --build; then
        echo -e "${GREEN}Containers rebuilt successfully${NC}"
        
        # Log action
        log_action "rebuild" "all" "Rebuilt containers"
    else
        echo -e "${RED}Failed to rebuild containers${NC}"
        return 1
    fi
}

# Function to clean Docker system
clean_system() {
    echo -e "${BLUE}Cleaning Docker system...${NC}"
    
    echo -e "${YELLOW}Removing unused containers...${NC}"
    docker container prune -f
    
    echo -e "${YELLOW}Removing unused images...${NC}"
    docker image prune -f
    
    echo -e "${YELLOW}Removing unused volumes...${NC}"
    docker volume prune -f
    
    echo -e "${YELLOW}Removing unused networks...${NC}"
    docker network prune -f
    
    echo -e "${GREEN}Docker system cleaned${NC}"
    
    # Log action
    log_action "clean" "system" "Cleaned Docker system"
}

# Function to backup data volumes
backup_volumes() {
    echo -e "${BLUE}Backing up data volumes...${NC}"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="./backups/docker/$timestamp"
    
    mkdir -p "$backup_dir"
    
    # Backup Postgres data
    docker run --rm \
        --volumes-from $(docker-compose -f "$COMPOSE_FILE" ps -q db) \
        -v "$backup_dir":/backup \
        alpine tar czf /backup/postgres_data.tar.gz /var/lib/postgresql/data
    
    # Backup Redis data
    docker run --rm \
        --volumes-from $(docker-compose -f "$COMPOSE_FILE" ps -q redis) \
        -v "$backup_dir":/backup \
        alpine tar czf /backup/redis_data.tar.gz /data
    
    echo -e "${GREEN}Volumes backed up to: $backup_dir${NC}"
    
    # Log action
    log_action "backup" "volumes" "Backed up data volumes"
}

# Function to restore data volumes
restore_volumes() {
    echo -e "${BLUE}Restoring data volumes...${NC}"
    
    # List available backups
    echo -e "\n${YELLOW}Available Backups:${NC}"
    ls -lt ./backups/docker/
    
    read -p "Enter backup timestamp to restore: " timestamp
    local backup_dir="./backups/docker/$timestamp"
    
    if [ ! -d "$backup_dir" ]; then
        echo -e "${RED}Backup directory not found${NC}"
        return 1
    fi
    
    # Stop containers
    docker-compose -f "$COMPOSE_FILE" down
    
    # Restore Postgres data
    docker run --rm \
        --volumes-from $(docker-compose -f "$COMPOSE_FILE" ps -q db) \
        -v "$backup_dir":/backup \
        alpine sh -c "cd / && tar xzf /backup/postgres_data.tar.gz"
    
    # Restore Redis data
    docker run --rm \
        --volumes-from $(docker-compose -f "$COMPOSE_FILE" ps -q redis) \
        -v "$backup_dir":/backup \
        alpine sh -c "cd / && tar xzf /backup/redis_data.tar.gz"
    
    # Start containers
    docker-compose -f "$COMPOSE_FILE" up -d
    
    echo -e "${GREEN}Volumes restored from: $backup_dir${NC}"
    
    # Log action
    log_action "restore" "volumes" "Restored data volumes"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/docker_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Docker Management Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Start Containers"
    echo -e "${YELLOW}2.${NC} Stop Containers"
    echo -e "${YELLOW}3.${NC} Show Status"
    echo -e "${YELLOW}4.${NC} View Logs"
    echo -e "${YELLOW}5.${NC} Rebuild Containers"
    echo -e "${YELLOW}6.${NC} Clean System"
    echo -e "${YELLOW}7.${NC} Backup Volumes"
    echo -e "${YELLOW}8.${NC} Restore Volumes"
    echo -e "${YELLOW}9.${NC} View Action Logs"
    echo -e "${YELLOW}0.${NC} Exit"
    echo "------------------------"
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (0-9): " choice
    
    case $choice in
        1)
            start_containers
            ;;
        2)
            stop_containers
            ;;
        3)
            show_status
            ;;
        4)
            view_logs
            ;;
        5)
            rebuild_containers
            ;;
        6)
            clean_system
            ;;
        7)
            backup_volumes
            ;;
        8)
            restore_volumes
            ;;
        9)
            if [ -f "$LOGS_DIR/docker_actions.log" ]; then
                less "$LOGS_DIR/docker_actions.log"
            else
                echo -e "${YELLOW}No Docker logs found${NC}"
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
