#!/bin/bash
# E2E Test Runner with Screenshot Capture
# This script runs Flutter integration tests and captures screenshots via ADB

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SCREENSHOTS_DIR="$PROJECT_DIR/screenshots/e2e"
DEVICE="${1:-emulator-5554}"
SCREENSHOT_COUNTER=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}📸 E2E Test Runner with Screenshots${NC}"
echo "Device: $DEVICE"
echo "Screenshots: $SCREENSHOTS_DIR"
echo ""

# Setup screenshots directory
setup_screenshots() {
    mkdir -p "$SCREENSHOTS_DIR"
    # Clean old screenshots
    rm -f "$SCREENSHOTS_DIR"/*.png 2>/dev/null || true
    echo -e "${YELLOW}Cleaned old screenshots${NC}"
}

# Capture screenshot via ADB
capture_screenshot() {
    local name="$1"
    SCREENSHOT_COUNTER=$((SCREENSHOT_COUNTER + 1))
    local filename="$(printf '%02d_%s.png' $SCREENSHOT_COUNTER "$name")"
    local filepath="$SCREENSHOTS_DIR/$filename"
    
    adb -s "$DEVICE" exec-out screencap -p > "$filepath" 2>/dev/null
    
    if [ -f "$filepath" ] && [ -s "$filepath" ]; then
        echo -e "  ${GREEN}📸${NC} Saved: $filename"
    else
        echo -e "  ${RED}⚠️${NC} Failed: $filename"
        rm -f "$filepath"
    fi
}

# Wait for app to be ready
wait_for_app() {
    echo -e "${YELLOW}Waiting for app to launch...${NC}"
    sleep 3
}

# Run the complete test flow with screenshots
run_app_flow_test() {
    echo -e "\n${GREEN}=== App Flow Test ===${NC}"
    
    # Start the app
    echo "Launching app..."
    flutter run -d "$DEVICE" --no-pub --no-resident > /dev/null 2>&1 &
    FLUTTER_PID=$!
    
    wait_for_app
    capture_screenshot "01_home_screen"
    
    # Simulate tapping add button (via ADB input)
    echo "Tapping add button..."
    adb -s "$DEVICE" shell input tap 540 1800  # Approximate FAB position
    sleep 1
    capture_screenshot "02_add_connection_screen"
    
    # Fill form fields
    echo "Filling form..."
    # Tap on name field and type
    adb -s "$DEVICE" shell input tap 540 500
    sleep 0.5
    adb -s "$DEVICE" shell input text "Test_Connection"
    adb -s "$DEVICE" shell input keyevent KEYCODE_TAB
    
    adb -s "$DEVICE" shell input text "192.168.1.1"
    adb -s "$DEVICE" shell input keyevent KEYCODE_TAB
    
    adb -s "$DEVICE" shell input text "22"
    adb -s "$DEVICE" shell input keyevent KEYCODE_TAB
    
    adb -s "$DEVICE" shell input text "testuser"
    adb -s "$DEVICE" shell input keyevent KEYCODE_TAB
    
    adb -s "$DEVICE" shell input text "testpass"
    
    sleep 1
    capture_screenshot "03_form_filled"
    
    # Go back
    echo "Going back..."
    adb -s "$DEVICE" shell input keyevent KEYCODE_BACK
    sleep 1
    capture_screenshot "04_back_to_home"
    
    # Kill the app
    kill $FLUTTER_PID 2>/dev/null || true
    
    echo -e "${GREEN}✅ App flow test completed${NC}"
}

# Run Flutter integration test
run_flutter_test() {
    local test_file="$1"
    local test_name=$(basename "$test_file" .dart)
    
    echo -e "\n${GREEN}=== Running: $test_name ===${NC}"
    
    cd "$PROJECT_DIR"
    flutter test "$test_file" -d "$DEVICE" 2>&1 | while read -r line; do
        echo "  $line"
        
        # Capture screenshot when test indicates
        if [[ "$line" == *"Screenshot:"* ]] || [[ "$line" == *"📸"* ]]; then
            # Extract screenshot name if possible
            capture_screenshot "test_step"
        fi
    done
}

# Main
main() {
    setup_screenshots
    
    # Option 1: Run with manual ADB control (more reliable screenshots)
    if [ "$2" == "--manual" ]; then
        run_app_flow_test
    else
        # Option 2: Run Flutter test and capture screenshots at intervals
        echo -e "${YELLOW}Starting test with screenshot capture...${NC}"
        echo ""
        
        # Start screenshot capture in background
        (
            sleep 5
            capture_screenshot "01_initial"
            sleep 3
            capture_screenshot "02_after_load"
            sleep 3
            capture_screenshot "03_test_running"
            sleep 3
            capture_screenshot "04_final"
        ) &
        SCREENSHOT_PID=$!
        
        # Run the actual test
        cd "$PROJECT_DIR"
        flutter test integration_test/app_flow_test.dart -d "$DEVICE"
        TEST_RESULT=$?
        
        # Wait for screenshots
        wait $SCREENSHOT_PID 2>/dev/null || true
        
        if [ $TEST_RESULT -eq 0 ]; then
            echo -e "\n${GREEN}✅ All tests passed${NC}"
        else
            echo -e "\n${RED}❌ Some tests failed${NC}"
        fi
    fi
    
    echo -e "\n${GREEN}📸 Screenshots saved to: $SCREENSHOTS_DIR${NC}"
    ls -la "$SCREENSHOTS_DIR"
}

main "$@"
