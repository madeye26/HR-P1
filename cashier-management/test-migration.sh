#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if a file exists
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} Found $1"
        return 0
    else
        echo -e "${RED}✗${NC} Missing $1"
        return 1
    }
}

# Function to check if a directory exists
check_directory() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} Found directory $1"
        return 0
    else
        echo -e "${RED}✗${NC} Missing directory $1"
        return 1
    }
}

# Function to check if package.json contains a dependency
check_dependency() {
    if grep -q "\"$1\":" package.json; then
        echo -e "${GREEN}✓${NC} Found dependency $1"
        return 0
    else
        echo -e "${RED}✗${NC} Missing dependency $1"
        return 1
    }
}

# Initialize error counter
errors=0

echo -e "\n${YELLOW}Testing Migration Results${NC}\n"

echo "Checking configuration files..."
check_file "package.json" || ((errors++))
check_file "tsconfig.json" || ((errors++))
check_file "tsconfig.node.json" || ((errors++))
check_file "vite.config.ts" || ((errors++))
check_file ".eslintrc.json" || ((errors++))
check_file "index.html" || ((errors++))

echo -e "\nChecking source files..."
check_file "src/App.tsx" || ((errors++))
check_file "src/main.tsx" || ((errors++))
check_file "src/types/index.ts" || ((errors++))

echo -e "\nChecking directories..."
check_directory "src/components" || ((errors++))
check_directory "src/context" || ((errors++))
check_directory "src/styles" || ((errors++))
check_directory "src/utils" || ((errors++))
check_directory "src/types" || ((errors++))

echo -e "\nChecking component files..."
check_file "src/components/Dashboard.tsx" || ((errors++))
check_file "src/components/EmployeeList.tsx" || ((errors++))
check_file "src/components/PayrollManagement.tsx" || ((errors++))
check_file "src/components/AttendanceManagement.tsx" || ((errors++))
check_file "src/components/LeaveManagement.tsx" || ((errors++))
check_file "src/components/DepartmentManagement.tsx" || ((errors++))
check_file "src/components/NotificationsManager.tsx" || ((errors++))
check_file "src/components/Settings.tsx" || ((errors++))

echo -e "\nChecking utility files..."
check_file "src/utils/payrollCalculations.ts" || ((errors++))
check_file "src/utils/attendanceManagement.ts" || ((errors++))
check_file "src/utils/notificationManager.ts" || ((errors++))
check_file "src/utils/reportGenerator.ts" || ((errors++))
check_file "src/utils/validationSchemas.ts" || ((errors++))

echo -e "\nChecking style files..."
check_file "src/styles/PayrollStyles.ts" || ((errors++))
check_file "src/styles/index.css" || ((errors++))

echo -e "\nChecking dependencies..."
check_dependency "@emotion/react" || ((errors++))
check_dependency "@emotion/styled" || ((errors++))
check_dependency "react-router-dom" || ((errors++))
check_dependency "react-hook-form" || ((errors++))
check_dependency "yup" || ((errors++))
check_dependency "jspdf" || ((errors++))
check_dependency "typescript" || ((errors++))

echo -e "\nChecking TypeScript configuration..."
if grep -q "\"strict\": true" tsconfig.json; then
    echo -e "${GREEN}✓${NC} TypeScript strict mode is enabled"
else
    echo -e "${RED}✗${NC} TypeScript strict mode is not enabled"
    ((errors++))
fi

echo -e "\nChecking backup directory..."
if [ -d "backup" ]; then
    echo -e "${GREEN}✓${NC} Backup directory exists"
else
    echo -e "${YELLOW}!${NC} No backup directory found (this is okay if this is a fresh install)"
fi

# Final summary
echo -e "\n${YELLOW}Test Summary${NC}"
if [ $errors -eq 0 ]; then
    echo -e "${GREEN}All checks passed successfully!${NC}"
    echo "You can now start the development server with: npm run dev"
else
    echo -e "${RED}Found $errors error(s)${NC}"
    echo "Please check the migration guide and fix the issues before proceeding"
fi

# Try to run TypeScript compiler
echo -e "\n${YELLOW}Running TypeScript compiler...${NC}"
if npx tsc --noEmit; then
    echo -e "${GREEN}✓${NC} TypeScript compilation successful"
else
    echo -e "${RED}✗${NC} TypeScript compilation failed"
    ((errors++))
fi

# Exit with error code if there were any errors
exit $errors
