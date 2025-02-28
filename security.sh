#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SECURITY_DIR="./security"
LOGS_DIR="./logs/security"
BACKUP_DIR="./backups/security"
TEMP_DIR="./temp/security"

# Create directories
mkdir -p "$SECURITY_DIR" "$LOGS_DIR" "$BACKUP_DIR" "$TEMP_DIR"

# Function to run security audit
run_audit() {
    echo -e "${BLUE}Running security audit...${NC}"
    
    local report_file="$SECURITY_DIR/audit_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير التدقيق الأمني"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## تدقيق التبعيات"
        echo "\`\`\`"
        npm audit
        echo "\`\`\`"
        echo
        
        echo "## فحص الثغرات الأمنية"
        echo "\`\`\`"
        npm audit --audit-level=high
        echo "\`\`\`"
        echo
        
        echo "## تدقيق التكوين"
        echo
        # Check environment files
        echo "### ملفات البيئة"
        for env_file in .env*; do
            if [ -f "$env_file" ]; then
                echo "- $env_file exists"
                if grep -q "SECRET\|KEY\|PASS\|TOKEN" "$env_file"; then
                    echo "  ⚠️ Contains sensitive information"
                fi
            fi
        done
        echo
        
        echo "### تكوين الأمان"
        if [ -f "package.json" ]; then
            echo "Security headers: $(jq -r '.dependencies["helmet"] // "Not found"' package.json)"
            echo "CORS: $(jq -r '.dependencies["cors"] // "Not found"' package.json)"
            echo "Rate limiting: $(jq -r '.dependencies["express-rate-limit"] // "Not found"' package.json)"
        fi
        echo
        
        echo "## فحص الملفات الحساسة"
        echo "\`\`\`"
        find . -type f -name "*.key" -o -name "*.pem" -o -name "*.p12" | grep -v "node_modules"
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Audit report generated: $report_file${NC}"
    
    # Log action
    log_action "audit" "system" "Generated security audit report"
}

# Function to check permissions
check_permissions() {
    echo -e "${BLUE}Checking file permissions...${NC}"
    
    local report_file="$SECURITY_DIR/permissions_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير صلاحيات الملفات"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## الملفات الحساسة"
        echo "\`\`\`"
        find . -type f -perm -o+w ! -path "./node_modules/*" ! -path "./.git/*"
        echo "\`\`\`"
        echo
        
        echo "## المجلدات الحساسة"
        echo "\`\`\`"
        find . -type d -perm -o+w ! -path "./node_modules/*" ! -path "./.git/*"
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Permissions report generated: $report_file${NC}"
    
    # Log action
    log_action "permissions" "files" "Checked file permissions"
}

# Function to manage secrets
manage_secrets() {
    echo -e "${BLUE}Managing secrets...${NC}"
    
    echo "Select action:"
    echo "1. Generate new secret"
    echo "2. Rotate secrets"
    echo "3. Check for exposed secrets"
    read -p "Enter choice (1-3): " choice
    
    case $choice in
        1)
            read -p "Enter secret name: " secret_name
            local secret=$(openssl rand -hex 32)
            echo "$secret_name=$secret" >> "$SECURITY_DIR/secrets.env"
            echo -e "${GREEN}Secret generated and saved${NC}"
            ;;
        2)
            if [ -f "$SECURITY_DIR/secrets.env" ]; then
                # Backup current secrets
                cp "$SECURITY_DIR/secrets.env" "$BACKUP_DIR/secrets_$(date +%Y%m%d_%H%M%S).env"
                
                # Rotate each secret
                while IFS='=' read -r name value; do
                    local new_secret=$(openssl rand -hex 32)
                    sed -i "s/$name=.*/$name=$new_secret/" "$SECURITY_DIR/secrets.env"
                done < "$SECURITY_DIR/secrets.env"
                
                echo -e "${GREEN}Secrets rotated${NC}"
            else
                echo -e "${RED}No secrets file found${NC}"
            fi
            ;;
        3)
            echo -e "${YELLOW}Checking for exposed secrets...${NC}"
            git grep -l "SECRET\|KEY\|PASS\|TOKEN" -- ':!security.sh' ':!*.md'
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            return 1
            ;;
    esac
    
    # Log action
    log_action "secrets" "manage" "Managed secrets"
}

# Function to manage SSL certificates
manage_certificates() {
    echo -e "${BLUE}Managing SSL certificates...${NC}"
    
    echo "Select action:"
    echo "1. Generate self-signed certificate"
    echo "2. Check certificate expiry"
    echo "3. Backup certificates"
    read -p "Enter choice (1-3): " choice
    
    case $choice in
        1)
            local cert_dir="$SECURITY_DIR/certificates"
            mkdir -p "$cert_dir"
            
            openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                -keyout "$cert_dir/private.key" \
                -out "$cert_dir/certificate.crt" \
                -subj "/CN=localhost"
            
            echo -e "${GREEN}Self-signed certificate generated${NC}"
            ;;
        2)
            if [ -f "$SECURITY_DIR/certificates/certificate.crt" ]; then
                openssl x509 -in "$SECURITY_DIR/certificates/certificate.crt" -noout -dates
            else
                echo -e "${RED}No certificate found${NC}"
            fi
            ;;
        3)
            if [ -d "$SECURITY_DIR/certificates" ]; then
                local backup_file="$BACKUP_DIR/certificates_$(date +%Y%m%d_%H%M%S).tar.gz"
                tar -czf "$backup_file" -C "$SECURITY_DIR" certificates/
                echo -e "${GREEN}Certificates backed up: $backup_file${NC}"
            else
                echo -e "${RED}No certificates to backup${NC}"
            fi
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            return 1
            ;;
    esac
    
    # Log action
    log_action "certificates" "manage" "Managed SSL certificates"
}

# Function to configure security settings
configure_security() {
    echo -e "${BLUE}Configuring security settings...${NC}"
    
    local config_file="$SECURITY_DIR/security.json"
    
    # Create or update security configuration
    cat > "$config_file" << EOL
{
    "headers": {
        "helmet": true,
        "cors": {
            "enabled": true,
            "origins": ["http://localhost:3000"],
            "methods": ["GET", "POST", "PUT", "DELETE"]
        },
        "csp": {
            "enabled": true,
            "directives": {
                "default-src": ["'self'"],
                "script-src": ["'self'"],
                "style-src": ["'self'"]
            }
        }
    },
    "rateLimit": {
        "enabled": true,
        "windowMs": 900000,
        "max": 100
    },
    "session": {
        "secure": true,
        "httpOnly": true,
        "sameSite": "strict"
    },
    "auth": {
        "passwordMinLength": 12,
        "requireSpecialChar": true,
        "requireNumber": true,
        "requireUppercase": true,
        "maxLoginAttempts": 5,
        "lockoutTime": 900
    }
}
EOL
    
    echo -e "${GREEN}Security configuration updated${NC}"
    
    # Log action
    log_action "configure" "settings" "Updated security configuration"
}

# Function to monitor security
monitor_security() {
    echo -e "${BLUE}Monitoring security...${NC}"
    
    local report_file="$SECURITY_DIR/monitoring_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير مراقبة الأمان"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## محاولات تسجيل الدخول الفاشلة"
        if [ -f "$LOGS_DIR/auth.log" ]; then
            grep "Failed login" "$LOGS_DIR/auth.log" | tail -n 10
        else
            echo "No authentication logs found"
        fi
        echo
        
        echo "## نشاط غير عادي"
        if [ -f "$LOGS_DIR/access.log" ]; then
            grep -i "error\|warning\|alert" "$LOGS_DIR/access.log" | tail -n 10
        else
            echo "No access logs found"
        fi
        echo
        
        echo "## حالة الخدمات"
        echo "\`\`\`"
        ps aux | grep -i "node\|npm"
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Security monitoring report generated: $report_file${NC}"
    
    # Log action
    log_action "monitor" "security" "Generated security monitoring report"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/security_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Security Management Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Run Security Audit"
    echo -e "${YELLOW}2.${NC} Check Permissions"
    echo -e "${YELLOW}3.${NC} Manage Secrets"
    echo -e "${YELLOW}4.${NC} Manage Certificates"
    echo -e "${YELLOW}5.${NC} Configure Security"
    echo -e "${YELLOW}6.${NC} Monitor Security"
    echo -e "${YELLOW}7.${NC} View Logs"
    echo -e "${YELLOW}0.${NC} Exit"
    echo "------------------------"
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (0-7): " choice
    
    case $choice in
        1)
            run_audit
            ;;
        2)
            check_permissions
            ;;
        3)
            manage_secrets
            ;;
        4)
            manage_certificates
            ;;
        5)
            configure_security
            ;;
        6)
            monitor_security
            ;;
        7)
            if [ -f "$LOGS_DIR/security_actions.log" ]; then
                less "$LOGS_DIR/security_actions.log"
            else
                echo -e "${YELLOW}No security logs found${NC}"
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
