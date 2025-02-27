#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script paths
SCRIPTS=(
    "manage.sh"
    "setup.sh"
    "dev.sh"
    "deploy.sh"
    "migrate.sh"
    "test.sh"
    "version.sh"
    "tools.sh"
    "db.sh"
    "docker.sh"
    "debug.sh"
    "security.sh"
    "optimize.sh"
    "i18n.sh"
    "docs.sh"
    "a11y.sh"
    "monitor.sh"
    "cleanup.sh"
    "audit.sh"
    "ci.sh"
)

# Function to show header
show_header() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════╗"
    echo "║        نظام إدارة الرواتب - التهيئة        ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Function to make scripts executable
make_executable() {
    local script=$1
    if [ -f "$script" ]; then
        chmod +x "$script"
        echo -e "${GREEN}✓${NC} Made $script executable"
    else
        echo -e "${RED}✗${NC} Script not found: $script"
        return 1
    fi
}

# Function to verify script
verify_script() {
    local script=$1
    if [ -x "$script" ]; then
        if bash -n "$script" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} $script syntax is valid"
            return 0
        else
            echo -e "${RED}✗${NC} $script has syntax errors"
            return 1
        fi
    fi
    return 1
}

# Function to create aliases
create_aliases() {
    local alias_file=".bash_aliases"
    
    # Create aliases file if it doesn't exist
    touch "$alias_file"
    
    # Add aliases for each script
    for script in "${SCRIPTS[@]}"; do
        local name=$(basename "$script" .sh)
        echo "alias cm-$name='./$(basename "$script")'" >> "$alias_file"
    done
    
    echo -e "${GREEN}Created aliases in $alias_file${NC}"
    echo "Please run 'source $alias_file' to enable aliases"
}

# Function to verify environment
verify_environment() {
    echo -e "\n${BLUE}Verifying environment...${NC}"
    
    # Check Node.js
    if command -v node &> /dev/null; then
        echo -e "${GREEN}✓${NC} Node.js $(node --version)"
    else
        echo -e "${RED}✗${NC} Node.js not found"
    fi
    
    # Check npm
    if command -v npm &> /dev/null; then
        echo -e "${GREEN}✓${NC} npm $(npm --version)"
    else
        echo -e "${RED}✗${NC} npm not found"
    fi
    
    # Check Git
    if command -v git &> /dev/null; then
        echo -e "${GREEN}✓${NC} Git $(git --version)"
    else
        echo -e "${RED}✗${NC} Git not found"
    fi
    
    # Check Docker
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}✓${NC} Docker $(docker --version)"
    else
        echo -e "${RED}✗${NC} Docker not found"
    fi
}

# Function to create required directories
create_directories() {
    echo -e "\n${BLUE}Creating required directories...${NC}"
    
    local dirs=(
        "logs"
        "data"
        "backups"
        "reports"
        "temp"
        "ci"
        "docs"
    )
    
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            echo -e "${GREEN}✓${NC} Created $dir directory"
        else
            echo -e "${YELLOW}!${NC} Directory $dir already exists"
        fi
    done
}

# Function to initialize git hooks
init_git_hooks() {
    echo -e "\n${BLUE}Initializing Git hooks...${NC}"
    
    local hooks_dir=".git/hooks"
    
    # Create pre-commit hook
    cat > "$hooks_dir/pre-commit" << 'EOL'
#!/bin/bash
./test.sh
./lint.sh
EOL
    chmod +x "$hooks_dir/pre-commit"
    
    # Create pre-push hook
    cat > "$hooks_dir/pre-push" << 'EOL'
#!/bin/bash
./ci.sh
EOL
    chmod +x "$hooks_dir/pre-push"
    
    echo -e "${GREEN}Git hooks initialized${NC}"
}

# Function to show completion message
show_completion() {
    echo -e "\n${GREEN}Initialization completed!${NC}"
    echo -e "\nAvailable commands:"
    
    for script in "${SCRIPTS[@]}"; do
        local name=$(basename "$script" .sh)
        echo -e "${YELLOW}cm-$name${NC} - Run $script"
    done
    
    echo -e "\nOr use ${YELLOW}./manage.sh${NC} for the main management interface"
}

# Main execution
show_header

echo -e "${BLUE}Initializing management scripts...${NC}\n"

# Make scripts executable and verify syntax
for script in "${SCRIPTS[@]}"; do
    if make_executable "$script"; then
        verify_script "$script"
    fi
done

# Create aliases
create_aliases

# Verify environment
verify_environment

# Create directories
create_directories

# Initialize git hooks if in git repository
if git rev-parse --git-dir > /dev/null 2>&1; then
    init_git_hooks
fi

# Show completion message
show_completion

# Make this script executable
chmod +x "$0"

echo -e "\nPress Enter to continue..."
read
