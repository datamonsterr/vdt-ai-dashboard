#!/bin/bash

# Ultra-optimized Script to convert Mermaid diagrams to PNG images
# Usage: ./convert_diagrams_ultra.sh [max_jobs] [--use-c-processor]

# Enable job control for background processing
set +m

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Directories
DIAGRAMS_DIR="$PROJECT_ROOT/docs/diagrams"
OUTPUT_DIR="$PROJECT_ROOT/docs/output/diagrams"

# Parse arguments
USE_C_PROCESSOR=false
MAX_JOBS=${1:-$(nproc 2>/dev/null || echo 4)}

for arg in "$@"; do
    case $arg in
        --use-c-processor)
            USE_C_PROCESSOR=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [max_jobs] [--use-c-processor]"
            echo "  max_jobs: Number of concurrent jobs (default: number of CPU cores)"
            echo "  --use-c-processor: Use compiled C processor for maximum performance"
            exit 0
            ;;
        [0-9]*)
            MAX_JOBS=$arg
            shift
            ;;
    esac
done

echo -e "${PURPLE}⚡ Ultra-optimized Mermaid Diagram Converter${NC}"
echo -e "${BLUE}🚀 Mode: $([ "$USE_C_PROCESSOR" = true ] && echo "C-Accelerated" || echo "Shell-Optimized")${NC}"

# Check if C processor should be used and is available
C_PROCESSOR_PATH="$SCRIPT_DIR/file_processor"
if [ "$USE_C_PROCESSOR" = true ]; then
    if [ ! -f "$C_PROCESSOR_PATH" ]; then
        echo -e "${YELLOW}⚠️  C processor not found, building it...${NC}"
        cd "$SCRIPT_DIR"
        if make -s > /dev/null 2>&1; then
            echo -e "${GREEN}✅ C processor built successfully${NC}"
        else
            echo -e "${RED}❌ Failed to build C processor, falling back to shell mode${NC}"
            USE_C_PROCESSOR=false
        fi
        cd - > /dev/null
    fi
fi

echo -e "${YELLOW}Checking dependencies...${NC}"

# Check if mmdc is installed
if ! command -v mmdc &> /dev/null; then
    echo -e "${RED}Error: mermaid-cli (mmdc) is not installed.${NC}"
    echo "Install it with: npm install -g @mermaid-js/mermaid-cli"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo -e "${YELLOW}Setting up Chrome for optimal performance...${NC}"

# Optimized Chrome path setup
CHROME_BASE_PATH="$HOME/.cache/puppeteer/chrome-headless-shell"
CHROME_PATH=""

if [ -d "$CHROME_BASE_PATH" ]; then
    CHROME_PATH=$(find "$CHROME_BASE_PATH" -name "chrome-headless-shell" -type f -executable 2>/dev/null | head -1)
fi

if [ -z "$CHROME_PATH" ] || [ ! -f "$CHROME_PATH" ]; then
    echo -e "${YELLOW}Chrome not found, installing puppeteer Chrome...${NC}"
    if npx puppeteer browsers install chrome-headless-shell >/dev/null 2>&1; then
        CHROME_PATH=$(find "$CHROME_BASE_PATH" -name "chrome-headless-shell" -type f -executable 2>/dev/null | head -1)
    fi
fi

if [ -n "$CHROME_PATH" ] && [ -f "$CHROME_PATH" ]; then
    echo -e "${GREEN}✓ Using Chrome at: $CHROME_PATH${NC}"
else
    echo -e "${RED}⚠ Warning: Could not find Chrome executable.${NC}"
fi

# Use C processor if requested and available
if [ "$USE_C_PROCESSOR" = true ] && [ -f "$C_PROCESSOR_PATH" ]; then
    echo -e "${PURPLE}🔥 Using C-accelerated processor with native threading${NC}"
    exec "$C_PROCESSOR_PATH" "$DIAGRAMS_DIR" "$OUTPUT_DIR" "$CHROME_PATH" "$MAX_JOBS"
    exit $?
fi

# Fallback to optimized shell implementation
TEMP_DIR=$(mktemp -d)
PROGRESS_FILE="$TEMP_DIR/progress"
RESULTS_FILE="$TEMP_DIR/results"

# Initialize progress tracking
echo "0" > "$PROGRESS_FILE.converted"
echo "0" > "$PROGRESS_FILE.failed" 
echo "0" > "$PROGRESS_FILE.total"
touch "$RESULTS_FILE.success"
touch "$RESULTS_FILE.failed"

# Cleanup function
cleanup() {
    jobs -p | xargs -r kill 2>/dev/null || true
    rm -rf "$TEMP_DIR" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Thread-safe counter functions
increment_counter() {
    local counter_file="$1"
    local lock_file="${counter_file}.lock"
    (
        flock 200
        local current=$(cat "$counter_file" 2>/dev/null || echo 0)
        echo $((current + 1)) > "$counter_file"
    ) 200>"$lock_file"
}

get_counter() {
    cat "$1" 2>/dev/null || echo 0
}

show_progress() {
    local converted=$(get_counter "$PROGRESS_FILE.converted")
    local failed=$(get_counter "$PROGRESS_FILE.failed")
    local total=$(get_counter "$PROGRESS_FILE.total")
    local processed=$((converted + failed))
    
    if [ "$total" -gt 0 ]; then
        local percent=$((processed * 100 / total))
        printf "\r${BLUE}Progress: %d%% (%d/%d) | ✅ %d | ❌ %d${NC}" "$percent" "$processed" "$total" "$converted" "$failed"
    fi
}

# Optimized worker function
convert_diagram() {
    local file="$1"
    local diagrams_dir="$2"
    local output_dir="$3"
    local chrome_path="$4"
    
    if [ -n "$chrome_path" ] && [ -f "$chrome_path" ]; then
        export PUPPETEER_EXECUTABLE_PATH="$chrome_path"
    fi
    
    local output_file="$output_dir/${file%.mmd}.png"
    
    if timeout 30s mmdc -i "$diagrams_dir/$file" -o "$output_file" -t dark -b transparent >/dev/null 2>&1; then
        echo "$file" >> "$RESULTS_FILE.success"
        increment_counter "$PROGRESS_FILE.converted"
        return 0
    else
        echo "$file" >> "$RESULTS_FILE.failed"
        increment_counter "$PROGRESS_FILE.failed"
        return 1
    fi
}

wait_for_jobs() {
    while [ $(jobs -r | wc -l) -ge "$MAX_JOBS" ]; do
        sleep 0.05
        show_progress
    done
}

# Process files
cd "$DIAGRAMS_DIR" || exit 1
file_list=(*.mmd)
if [ ! -f "${file_list[0]}" ]; then
    echo -e "${YELLOW}No .mmd files found in $DIAGRAMS_DIR${NC}"
    exit 0
fi

total_files=${#file_list[@]}
echo "$total_files" > "$PROGRESS_FILE.total"

echo -e "${BLUE}📊 Found $total_files diagram files to convert${NC}"
echo -e "${BLUE}🔧 Using $MAX_JOBS concurrent shell workers${NC}"
echo

start_time=$(date +%s)

echo -e "${YELLOW}Starting shell-optimized conversion...${NC}"
for file in "${file_list[@]}"; do
    if [ -f "$file" ]; then
        wait_for_jobs
        convert_diagram "$file" "$DIAGRAMS_DIR" "$OUTPUT_DIR" "$CHROME_PATH" &
        sleep 0.02
    fi
done

echo -e "\n${BLUE}⏳ Waiting for all jobs to complete...${NC}"
while [ $(jobs -r | wc -l) -gt 0 ]; do
    sleep 0.1
    show_progress
done

show_progress
echo

# Performance summary
end_time=$(date +%s)
duration=$((end_time - start_time))
converted_count=$(get_counter "$PROGRESS_FILE.converted")
failed_count=$(get_counter "$PROGRESS_FILE.failed")

echo -e "\n${GREEN}🎉 Conversion complete!${NC}"
echo -e "${BLUE}📈 Performance Summary:${NC}"
echo -e "   ⏱️  Duration: ${BLUE}${duration}s${NC}"
echo -e "   ✅ Successfully converted: ${GREEN}$converted_count${NC} diagrams"

if [ "$converted_count" -gt 0 ] && [ "$duration" -gt 0 ]; then
    throughput=$((converted_count * 60 / duration))
    echo -e "   🚀 Throughput: ${BLUE}~$throughput diagrams/minute${NC}"
fi

if [ "$failed_count" -gt 0 ]; then
    echo -e "   ❌ Failed conversions: ${RED}$failed_count${NC} diagrams"
fi

echo -e "\n${YELLOW}📁 PNG files are available in: $OUTPUT_DIR${NC}"
echo -e "${PURPLE}💡 Pro tip: Use --use-c-processor for maximum performance!${NC}"

exit $([ "$converted_count" -eq 0 ] && [ "$failed_count" -gt 0 ] && echo 1 || echo 0)
