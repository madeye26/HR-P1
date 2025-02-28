#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPTS_DIR="."
LOG_FILE="./logs/management.log"

# Create logs directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Function to show header
show_header() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                   نظام إدارة المحاسبة                      ║"
    echo "║                Cashier Management System                    ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Function to check script exists and is executable
check_script() {
    local script=$1
    if [ ! -f "$SCRIPTS_DIR/$script" ]; then
        echo -e "${RED}Error: Script $script not found${NC}"
        return 1
    fi
    if [ ! -x "$SCRIPTS_DIR/$script" ]; then
        chmod +x "$SCRIPTS_DIR/$script"
    fi
    return 0
}

# Function to log action
log_action() {
    local action=$1
    local details=$2
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $details" >> "$LOG_FILE"
}

# Function to show sales menu
show_sales_menu() {
    echo -e "\n${BLUE}Sales & Customer Management${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Sales Management"
    echo -e "${YELLOW}2.${NC} Customer Management"
    echo -e "${YELLOW}3.${NC} Return to Main Menu"
    echo "------------------------"
    
    read -p "Enter your choice (1-3): " choice
    
    case $choice in
        1)
            check_script "sales.sh" && ./sales.sh
            log_action "sales" "Accessed sales management"
            ;;
        2)
            check_script "customers.sh" && ./customers.sh
            log_action "customers" "Accessed customer management"
            ;;
        3)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            sleep 1
            ;;
    esac
}

# Function to show inventory menu
show_inventory_menu() {
    echo -e "\n${BLUE}Inventory & Purchase Management${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Inventory Management"
    echo -e "${YELLOW}2.${NC} Purchase Orders"
    echo -e "${YELLOW}3.${NC} Supplier Management"
    echo -e "${YELLOW}4.${NC} Return to Main Menu"
    echo "------------------------"
    
    read -p "Enter your choice (1-4): " choice
    
    case $choice in
        1)
            check_script "inventory.sh" && ./inventory.sh
            log_action "inventory" "Accessed inventory management"
            ;;
        2)
            check_script "purchase.sh" && ./purchase.sh
            log_action "purchase" "Accessed purchase management"
            ;;
        3)
            check_script "suppliers.sh" && ./suppliers.sh
            log_action "suppliers" "Accessed supplier management"
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            sleep 1
            ;;
    esac
}

# Function to show employee menu
show_employee_menu() {
    echo -e "\n${BLUE}Employee & HR Management${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Employee Management"
    echo -e "${YELLOW}2.${NC} Attendance Management"
    echo -e "${YELLOW}3.${NC} Leave Management"
    echo -e "${YELLOW}4.${NC} Payroll Management"
    echo -e "${YELLOW}5.${NC} Department Management"
    echo -e "${YELLOW}6.${NC} Return to Main Menu"
    echo "------------------------"
    
    read -p "Enter your choice (1-6): " choice
    
    case $choice in
        1)
            check_script "employees.sh" && ./employees.sh
            log_action "employees" "Accessed employee management"
            ;;
        2)
            check_script "attendance.sh" && ./attendance.sh
            log_action "attendance" "Accessed attendance management"
            ;;
        3)
            check_script "leave.sh" && ./leave.sh
            log_action "leave" "Accessed leave management"
            ;;
        4)
            check_script "payroll.sh" && ./payroll.sh
            log_action "payroll" "Accessed payroll management"
            ;;
        5)
            check_script "departments.sh" && ./departments.sh
            log_action "departments" "Accessed department management"
            ;;
        6)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            sleep 1
            ;;
    esac
}

# Function to show system menu
show_system_menu() {
    echo -e "\n${BLUE}System Management${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} User Management"
    echo -e "${YELLOW}2.${NC} Configuration"
    echo -e "${YELLOW}3.${NC} Backup Management"
    echo -e "${YELLOW}4.${NC} Log Management"
    echo -e "${YELLOW}5.${NC} Cache Management"
    echo -e "${YELLOW}6.${NC} Task Management"
    echo -e "${YELLOW}7.${NC} Return to Main Menu"
    echo "------------------------"
    
    read -p "Enter your choice (1-7): " choice
    
    case $choice in
        1)
            check_script "users.sh" && ./users.sh
            log_action "users" "Accessed user management"
            ;;
        2)
            check_script "config.sh" && ./config.sh
            log_action "config" "Accessed configuration management"
            ;;
        3)
            check_script "backup.sh" && ./backup.sh
            log_action "backup" "Accessed backup management"
            ;;
        4)
            check_script "logs.sh" && ./logs.sh
            log_action "logs" "Accessed log management"
            ;;
        5)
            check_script "cache.sh" && ./cache.sh
            log_action "cache" "Accessed cache management"
            ;;
        6)
            check_script "tasks.sh" && ./tasks.sh
            log_action "tasks" "Accessed task management"
            ;;
        7)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            sleep 1
            ;;
    esac
}

# Function to show main menu
show_main_menu() {
    echo -e "\n${BLUE}Main Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Sales & Customer Management"
    echo -e "${YELLOW}2.${NC} Inventory & Purchase Management"
    echo -e "${YELLOW}3.${NC} Employee & HR Management"
    echo -e "${YELLOW}4.${NC} System Management"
    echo -e "${YELLOW}5.${NC} Reports"
    echo -e "${YELLOW}6.${NC} Notifications"
    echo -e "${YELLOW}0.${NC} Exit"
    echo "------------------------"
}

# Main loop
while true; do
    show_header
    show_main_menu
    
    read -p "Enter your choice (0-6): " choice
    
    case $choice in
        1)
            show_sales_menu
            ;;
        2)
            show_inventory_menu
            ;;
        3)
            show_employee_menu
            ;;
        4)
            show_system_menu
            ;;
        5)
            check_script "report.sh" && ./report.sh
            log_action "reports" "Accessed reports"
            ;;
        6)
            check_script "notify.sh" && ./notify.sh
            log_action "notifications" "Accessed notifications"
            ;;
        0)
            echo -e "\n${GREEN}Thank you for using Cashier Management System${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${RED}Invalid option${NC}"
            sleep 1
            ;;
    esac
done
