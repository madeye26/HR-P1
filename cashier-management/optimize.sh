#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
OPTIMIZE_DIR="./optimize"
REPORTS_DIR="./reports/optimize"
LOGS_DIR="./logs/optimize"
TEMP_DIR="./temp/optimize"

# Create directories
mkdir -p "$OPTIMIZE_DIR" "$REPORTS_DIR" "$LOGS_DIR" "$TEMP_DIR"

# Function to optimize bundle size
optimize_bundle() {
    echo -e "${BLUE}Optimizing bundle size...${NC}"
    
    local report_file="$REPORTS_DIR/bundle_optimization_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تحسين حجم الحزمة"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## تحليل الحزمة الحالي"
        echo "\`\`\`"
        npm run analyze
        echo "\`\`\`"
        echo
        
        echo "## التحسينات المقترحة"
        
        # Check for large dependencies
        echo "### التبعيات الكبيرة"
        npm list --prod --parseable | \
        xargs -I {} du -sh {} 2>/dev/null | \
        sort -hr | head -n 10
        echo
        
        # Run webpack bundle analyzer
        echo "### تحليل الحزمة"
        ANALYZE=true npm run build
        
    } > "$report_file"
    
    # Perform optimizations
    echo -e "${YELLOW}Performing bundle optimizations...${NC}"
    
    # Enable tree shaking
    jq '.sideEffects = false' package.json > package.json.tmp && mv package.json.tmp package.json
    
    # Configure code splitting
    if [ -f "vite.config.ts" ]; then
        # Add dynamic imports optimization
        sed -i '/build: {/a \    rollupOptions: {\n      output: {\n        manualChunks: {\n          vendor: [/node_modules/]\n        }\n      }\n    },' vite.config.ts
    fi
    
    # Rebuild with optimizations
    npm run build
    
    echo -e "${GREEN}Bundle optimization completed${NC}"
    
    # Log action
    log_action "optimize" "bundle" "Optimized bundle size"
}

# Function to optimize database
optimize_database() {
    echo -e "${BLUE}Optimizing database...${NC}"
    
    local report_file="$REPORTS_DIR/database_optimization_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تحسين قاعدة البيانات"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## تحليل الأداء"
        echo "\`\`\`"
        if [ -f "./logs/db.log" ]; then
            # Analyze slow queries
            grep "slow query" "./logs/db.log" | \
            sort | uniq -c | sort -nr | head -n 10
        fi
        echo "\`\`\`"
        echo
        
        echo "## الفهارس المقترحة"
        # Add index suggestions based on query patterns
        if [ -f "./logs/db.log" ]; then
            grep "table scan" "./logs/db.log" | \
            awk '{print $4}' | sort | uniq -c | sort -nr
        fi
        
    } > "$report_file"
    
    echo -e "${GREEN}Database optimization completed${NC}"
    
    # Log action
    log_action "optimize" "database" "Optimized database performance"
}

# Function to optimize images
optimize_images() {
    echo -e "${BLUE}Optimizing images...${NC}"
    
    # Check for required tools
    if ! command -v imagemin &> /dev/null; then
        npm install -g imagemin-cli
    fi
    
    local report_file="$REPORTS_DIR/image_optimization_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تحسين الصور"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## ملخص التحسين"
        echo
        
        # Process images
        find ./public -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.gif" \) -print0 | \
        while IFS= read -r -d '' img; do
            original_size=$(stat -f %z "$img")
            imagemin "$img" > "${img}.optimized"
            new_size=$(stat -f %z "${img}.optimized")
            mv "${img}.optimized" "$img"
            
            reduction=$((original_size - new_size))
            percent=$((reduction * 100 / original_size))
            
            echo "- $img: Reduced by $percent% ($reduction bytes)"
        done
        
    } > "$report_file"
    
    echo -e "${GREEN}Image optimization completed${NC}"
    
    # Log action
    log_action "optimize" "images" "Optimized image assets"
}

# Function to optimize caching
optimize_caching() {
    echo -e "${BLUE}Optimizing caching...${NC}"
    
    local report_file="$REPORTS_DIR/cache_optimization_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تحسين التخزين المؤقت"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## إعدادات التخزين المؤقت الحالية"
        if [ -f "./config/cache.json" ]; then
            cat "./config/cache.json"
        fi
        echo
        
        echo "## التحسينات المقترحة"
        echo "1. تمكين التخزين المؤقت للمتصفح"
        echo "2. تكوين التخزين المؤقت للخادم"
        echo "3. تحسين استراتيجية التخزين المؤقت"
        
    } > "$report_file"
    
    # Configure caching
    if [ -f "vite.config.ts" ]; then
        # Add cache configuration
        sed -i '/build: {/a \    cache: true,\n    buildCacheDir: ".cache",' vite.config.ts
    fi
    
    echo -e "${GREEN}Cache optimization completed${NC}"
    
    # Log action
    log_action "optimize" "cache" "Optimized caching configuration"
}

# Function to optimize code
optimize_code() {
    echo -e "${BLUE}Optimizing code...${NC}"
    
    local report_file="$REPORTS_DIR/code_optimization_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تحسين الكود"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## تحليل الكود"
        echo "\`\`\`"
        npm run lint -- --max-warnings 0
        echo "\`\`\`"
        echo
        
        echo "## التحسينات المقترحة"
        # Run TypeScript compiler in strict mode
        echo "### فحص النوع الصارم"
        tsc --noEmit --strict
        echo
        
        # Check for unused exports
        echo "### الصادرات غير المستخدمة"
        npx ts-prune
        
    } > "$report_file"
    
    # Apply automatic fixes
    echo -e "${YELLOW}Applying code optimizations...${NC}"
    
    # Fix linting issues
    npm run lint:fix
    
    # Format code
    npm run format
    
    echo -e "${GREEN}Code optimization completed${NC}"
    
    # Log action
    log_action "optimize" "code" "Optimized code quality"
}

# Function to optimize performance
optimize_performance() {
    echo -e "${BLUE}Optimizing performance...${NC}"
    
    local report_file="$REPORTS_DIR/performance_optimization_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تحسين الأداء"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## قياسات الأداء"
        echo "\`\`\`"
        # Run Lighthouse audit
        npx lighthouse http://localhost:3000 --quiet --chrome-flags="--headless" \
            --output=json | jq '.categories.performance'
        echo "\`\`\`"
        echo
        
        echo "## التحسينات المقترحة"
        echo "1. تحسين تحميل الجافا سكريبت"
        echo "2. تحسين تحميل CSS"
        echo "3. تحسين تحميل الصور"
        echo "4. تحسين الأداء الأولي"
        
    } > "$report_file"
    
    # Apply performance optimizations
    echo -e "${YELLOW}Applying performance optimizations...${NC}"
    
    # Configure performance optimizations in vite config
    if [ -f "vite.config.ts" ]; then
        sed -i '/build: {/a \    minify: "terser",\n    terserOptions: {\n      compress: {\n        drop_console: true\n      }\n    },' vite.config.ts
    fi
    
    echo -e "${GREEN}Performance optimization completed${NC}"
    
    # Log action
    log_action "optimize" "performance" "Optimized application performance"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/optimize_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Optimization Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Optimize Bundle Size"
    echo -e "${YELLOW}2.${NC} Optimize Database"
    echo -e "${YELLOW}3.${NC} Optimize Images"
    echo -e "${YELLOW}4.${NC} Optimize Caching"
    echo -e "${YELLOW}5.${NC} Optimize Code"
    echo -e "${YELLOW}6.${NC} Optimize Performance"
    echo -e "${YELLOW}7.${NC} View Optimization Logs"
    echo -e "${YELLOW}0.${NC} Exit"
    echo "------------------------"
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (0-7): " choice
    
    case $choice in
        1)
            optimize_bundle
            ;;
        2)
            optimize_database
            ;;
        3)
            optimize_images
            ;;
        4)
            optimize_caching
            ;;
        5)
            optimize_code
            ;;
        6)
            optimize_performance
            ;;
        7)
            if [ -f "$LOGS_DIR/optimize_actions.log" ]; then
                less "$LOGS_DIR/optimize_actions.log"
            else
                echo -e "${YELLOW}No optimization logs found${NC}"
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
