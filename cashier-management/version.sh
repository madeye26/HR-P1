#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if in git repository
check_git() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}Error: Not in a git repository${NC}"
        exit 1
    fi
}

# Function to check for uncommitted changes
check_uncommitted() {
    if ! git diff-index --quiet HEAD --; then
        echo -e "${YELLOW}Warning: You have uncommitted changes${NC}"
        return 1
    fi
    return 0
}

# Function to update version in package.json
update_version() {
    local version_type=$1
    local current_version=$(node -p "require('./package.json').version")
    local major minor patch
    IFS='.' read -r major minor patch <<< "$current_version"
    
    case $version_type in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
    esac
    
    local new_version="$major.$minor.$patch"
    # Update package.json
    sed -i "s/\"version\": \"$current_version\"/\"version\": \"$new_version\"/" package.json
    echo "$new_version"
}

# Function to create changelog entry
create_changelog() {
    local version=$1
    local type=$2
    local date=$(date +%Y-%m-%d)
    local temp_file=$(mktemp)
    
    echo -e "## [$version] - $date\n" > "$temp_file"
    echo "### Changes" >> "$temp_file"
    echo "- $(git log -1 --pretty=%B)" >> "$temp_file"
    echo "" >> "$temp_file"
    
    if [ -f CHANGELOG.md ]; then
        cat CHANGELOG.md >> "$temp_file"
    fi
    
    mv "$temp_file" CHANGELOG.md
}

# Function to create release branch
create_release_branch() {
    local version=$1
    git checkout -b "release/v$version"
}

# Function to tag release
tag_release() {
    local version=$1
    local message=$2
    git tag -a "v$version" -m "$message"
}

# Function to merge release
merge_release() {
    local version=$1
    git checkout main
    git merge --no-ff "release/v$version" -m "Merge release v$version"
    git branch -d "release/v$version"
}

# Function to show version menu
show_menu() {
    echo -e "\n${BLUE}Version Management Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Create patch release"
    echo -e "${YELLOW}2.${NC} Create minor release"
    echo -e "${YELLOW}3.${NC} Create major release"
    echo -e "${YELLOW}4.${NC} Show current version"
    echo -e "${YELLOW}5.${NC} Show git status"
    echo -e "${YELLOW}6.${NC} Show changelog"
    echo -e "${YELLOW}7.${NC} Create hotfix"
    echo -e "${YELLOW}8.${NC} Push changes"
    echo -e "${YELLOW}0.${NC} Exit"
    echo "------------------------"
}

# Function to handle release creation
create_release() {
    local type=$1
    check_git
    
    if ! check_uncommitted; then
        read -p "Do you want to commit changes? (y/n): " answer
        if [[ $answer =~ ^[Yy]$ ]]; then
            read -p "Enter commit message: " message
            git add .
            git commit -m "$message"
        else
            return 1
        fi
    fi
    
    local new_version=$(update_version "$type")
    create_changelog "$new_version" "$type"
    create_release_branch "$new_version"
    
    git add package.json CHANGELOG.md
    git commit -m "Bump version to v$new_version"
    
    tag_release "$new_version" "Release version $new_version"
    merge_release "$new_version"
    
    echo -e "${GREEN}Successfully created $type release v$new_version${NC}"
}

# Function to create hotfix
create_hotfix() {
    check_git
    local current_version=$(node -p "require('./package.json').version")
    local hotfix_branch="hotfix/v$current_version"
    
    git checkout -b "$hotfix_branch"
    echo -e "${GREEN}Created hotfix branch: $hotfix_branch${NC}"
    echo -e "${YELLOW}Make your fixes and then run option 1 to create a patch release${NC}"
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (0-8): " choice
    
    case $choice in
        1)
            create_release "patch"
            ;;
        2)
            create_release "minor"
            ;;
        3)
            create_release "major"
            ;;
        4)
            version=$(node -p "require('./package.json').version")
            echo -e "\nCurrent version: ${GREEN}v$version${NC}"
            ;;
        5)
            git status
            ;;
        6)
            if [ -f CHANGELOG.md ]; then
                cat CHANGELOG.md
            else
                echo -e "${YELLOW}No changelog found${NC}"
            fi
            ;;
        7)
            create_hotfix
            ;;
        8)
            check_git
            git push --follow-tags
            echo -e "${GREEN}Successfully pushed changes${NC}"
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
