#!/bin/bash

# Function to backup original files
backup_files() {
    echo "Creating backup directory..."
    mkdir -p backup
    
    # Backup original files
    [ -f package.json ] && mv package.json backup/
    [ -f tsconfig.json ] && mv tsconfig.json backup/
    [ -f tsconfig.node.json ] && mv tsconfig.node.json backup/
    [ -f vite.config.ts ] && mv vite.config.ts backup/
    [ -f .eslintrc.json ] && mv .eslintrc.json backup/
    [ -f index.html ] && mv index.html backup/
    [ -f src/main.tsx ] && mv src/main.tsx backup/
    [ -f src/App.tsx ] && mv src/App.tsx backup/
    [ -f README.md ] && mv README.md backup/
}

# Function to rename new files
rename_new_files() {
    echo "Renaming new files..."
    [ -f package.new.json ] && mv package.new.json package.json
    [ -f tsconfig.new.json ] && mv tsconfig.new.json tsconfig.json
    [ -f tsconfig.node.new.json ] && mv tsconfig.node.new.json tsconfig.node.json
    [ -f vite.config.new.ts ] && mv vite.config.new.ts vite.config.ts
    [ -f .eslintrc.new.json ] && mv .eslintrc.new.json .eslintrc.json
    [ -f src/indexNew.html ] && mv src/indexNew.html index.html
    [ -f src/mainNew.tsx ] && mv src/mainNew.tsx src/main.tsx
    [ -f src/components/MainApp.tsx ] && mv src/components/MainApp.tsx src/App.tsx
    [ -f README.new.md ] && mv README.new.md README.md
}

# Function to clean up old component files
cleanup_old_components() {
    echo "Cleaning up old component files..."
    [ -f src/components/PayrollManagement.tsx ] && rm src/components/PayrollManagement.tsx
    [ -f src/components/EmployeeList.tsx ] && rm src/components/EmployeeList.tsx
    [ -f src/components/DepartmentManagement.tsx ] && rm src/components/DepartmentManagement.tsx
    [ -f src/components/PayrollManagementNew.tsx ] && mv src/components/PayrollManagementNew.tsx src/components/PayrollManagement.tsx
    [ -f src/components/EmployeeListNew.tsx ] && mv src/components/EmployeeListNew.tsx src/components/EmployeeList.tsx
    [ -f src/components/DepartmentsManager.tsx ] && mv src/components/DepartmentsManager.tsx src/components/DepartmentManagement.tsx
}

# Function to install dependencies
install_dependencies() {
    echo "Installing dependencies..."
    npm install
}

# Main execution
echo "Starting migration process..."

# Create backup
backup_files

# Rename new files
rename_new_files

# Clean up old components
cleanup_old_components

# Install dependencies
install_dependencies

echo "Migration completed successfully!"
echo "Please verify the changes and test the application."
echo "Backup of original files can be found in the 'backup' directory."
