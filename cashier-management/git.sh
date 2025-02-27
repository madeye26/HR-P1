#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GIT_DIR="./git"
LOGS_DIR="./logs/git"
REPORTS_DIR="./reports/git"
TEMP_DIR="./temp/git"

# Create directories
mkdir -p "$GIT_DIR" "$LOGS_DIR" "$REPORTS_DIR" "$TEMP_DIR"

# Function to create feature branch
create_feature() {
    echo -e "${BLUE}Creating feature branch...${NC}"
    
    read -p "Enter feature name: " feature_name
    feature_branch="feature/$(echo "$feature_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"
    
    # Check if branch exists
    if git show-ref --verify --quiet "refs/heads/$feature_branch"; then
        echo -e "${RED}Branch already exists${NC}"
        return 1
    fi
    
    # Create and switch to new branch
    if git checkout -b "$feature_branch"; then
        echo -e "${GREEN}Created and switched to branch: $feature_branch${NC}"
        
        # Log action
        log_action "create" "feature" "Created feature branch: $feature_branch"
    else
        echo -e "${RED}Failed to create branch${NC}"
        return 1
    fi
}

# Function to create hotfix branch
create_hotfix() {
    echo -e "${BLUE}Creating hotfix branch...${NC}"
    
    read -p "Enter hotfix name: " hotfix_name
    hotfix_branch="hotfix/$(echo "$hotfix_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"
    
    # Check if branch exists
    if git show-ref --verify --quiet "refs/heads/$hotfix_branch"; then
        echo -e "${RED}Branch already exists${NC}"
        return 1
    fi
    
    # Create and switch to new branch
    if git checkout -b "$hotfix_branch" main; then
        echo -e "${GREEN}Created and switched to branch: $hotfix_branch${NC}"
        
        # Log action
        log_action "create" "hotfix" "Created hotfix branch: $hotfix_branch"
    else
        echo -e "${RED}Failed to create branch${NC}"
        return 1
    fi
}

# Function to commit changes
commit_changes() {
    echo -e "${BLUE}Committing changes...${NC}"
    
    # Check for changes
    if ! git status --porcelain | grep '^[MARCD]'; then
        echo -e "${YELLOW}No changes to commit${NC}"
        return 1
    fi
    
    # Show changes
    git status
    
    read -p "Enter commit message: " commit_message
    
    # Stage and commit changes
    if git add . && git commit -m "$commit_message"; then
        echo -e "${GREEN}Changes committed${NC}"
        
        # Log action
        log_action "commit" "changes" "Committed changes: $commit_message"
    else
        echo -e "${RED}Failed to commit changes${NC}"
        return 1
    fi
}

# Function to merge branch
merge_branch() {
    echo -e "${BLUE}Merging branch...${NC}"
    
    # Show available branches
    echo -e "${YELLOW}Available branches:${NC}"
    git branch
    
    read -p "Enter branch to merge: " source_branch
    read -p "Enter target branch [main]: " target_branch
    target_branch=${target_branch:-main}
    
    # Check if branches exist
    if ! git show-ref --verify --quiet "refs/heads/$source_branch" || \
       ! git show-ref --verify --quiet "refs/heads/$target_branch"; then
        echo -e "${RED}One or both branches do not exist${NC}"
        return 1
    fi
    
    # Switch to target branch
    if git checkout "$target_branch"; then
        # Merge source branch
        if git merge "$source_branch"; then
            echo -e "${GREEN}Merged $source_branch into $target_branch${NC}"
            
            # Log action
            log_action "merge" "branch" "Merged $source_branch into $target_branch"
        else
            echo -e "${RED}Merge failed${NC}"
            return 1
        fi
    else
        echo -e "${RED}Failed to switch to target branch${NC}"
        return 1
    fi
}

# Function to push changes
push_changes() {
    echo -e "${BLUE}Pushing changes...${NC}"
    
    # Get current branch
    current_branch=$(git symbolic-ref --short HEAD)
    
    # Check for unpushed commits
    if ! git log origin/"$current_branch".."$current_branch" 2>/dev/null; then
        echo -e "${YELLOW}No changes to push${NC}"
        return 1
    fi
    
    # Push changes
    if git push origin "$current_branch"; then
        echo -e "${GREEN}Changes pushed to $current_branch${NC}"
        
        # Log action
        log_action "push" "changes" "Pushed changes to $current_branch"
    else
        echo -e "${RED}Failed to push changes${NC}"
        return 1
    fi
}

# Function to pull changes
pull_changes() {
    echo -e "${BLUE}Pulling changes...${NC}"
    
    # Get current branch
    current_branch=$(git symbolic-ref --short HEAD)
    
    # Pull changes
    if git pull origin "$current_branch"; then
        echo -e "${GREEN}Changes pulled from $current_branch${NC}"
        
        # Log action
        log_action "pull" "changes" "Pulled changes from $current_branch"
    else
        echo -e "${RED}Failed to pull changes${NC}"
        return 1
    fi
}

# Function to show branch status
show_status() {
    echo -e "${BLUE}Branch Status${NC}"
    echo "------------------------"
    
    # Show current branch
    echo -e "${YELLOW}Current branch:${NC} $(git symbolic-ref --short HEAD)"
    
    # Show status
    git status --short
    
    # Show last commit
    echo -e "\n${YELLOW}Last commit:${NC}"
    git log -1 --oneline
    
    # Show unpushed commits
    echo -e "\n${YELLOW}Unpushed commits:${NC}"
    git log @{u}.. --oneline 2>/dev/null || echo "None"
}

# Function to clean repository
clean_repo() {
    echo -e "${BLUE}Cleaning repository...${NC}"
    
    # Remove untracked files
    git clean -n
    read -p "Remove these files? (y/n): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        git clean -fd
        echo -e "${GREEN}Untracked files removed${NC}"
    fi
    
    # Remove merged branches
    echo -e "\n${YELLOW}Merged branches:${NC}"
    git branch --merged | grep -v "\*"
    read -p "Delete merged branches? (y/n): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        git branch --merged | grep -v "\*" | xargs -n 1 git branch -d
        echo -e "${GREEN}Merged branches deleted${NC}"
    fi
    
    # Prune remote branches
    git remote prune origin
    
    # Log action
    log_action "clean" "repo" "Cleaned repository"
}

# Function to generate report
generate_report() {
    echo -e "${BLUE}Generating Git report...${NC}"
    
    local report_file="$REPORTS_DIR/git_report_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير Git"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## الفروع"
        echo "\`\`\`"
        git branch -v
        echo "\`\`\`"
        echo
        
        echo "## آخر التعديلات"
        echo "\`\`\`"
        git log --oneline -n 10
        echo "\`\`\`"
        echo
        
        echo "## الإحصائيات"
        echo "\`\`\`"
        git shortlog -sn
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Git report generated: $report_file${NC}"
    
    # Log action
    log_action "generate" "report" "Generated Git report"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/git_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Git Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Create Feature Branch"
    echo -e "${YELLOW}2.${NC} Create Hotfix Branch"
    echo -e "${YELLOW}3.${NC} Commit Changes"
    echo -e "${YELLOW}4.${NC} Merge Branch"
    echo -e "${YELLOW}5.${NC} Push Changes"
    echo -e "${YELLOW}6.${NC} Pull Changes"
    echo -e "${YELLOW}7.${NC} Show Status"
    echo -e "${YELLOW}8.${NC} Clean Repository"
    echo -e "${YELLOW}9.${NC} Generate Report"
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
            create_feature
            ;;
        2)
            create_hotfix
            ;;
        3)
            commit_changes
            ;;
        4)
            merge_branch
            ;;
        5)
            push_changes
            ;;
        6)
            pull_changes
            ;;
        7)
            show_status
            ;;
        8)
            clean_repo
            ;;
        9)
            generate_report
            ;;
        10)
            if [ -f "$LOGS_DIR/git_actions.log" ]; then
                less "$LOGS_DIR/git_actions.log"
            else
                echo -e "${YELLOW}No Git logs found${NC}"
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
