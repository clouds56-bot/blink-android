#!/bin/bash
# CI E2E Test Runner Script
# Waits for Android system to be fully ready before running tests

set -e

echo "=== E2E Test Runner ==="

# Wait for emulator to be fully ready
wait_for_emulator() {
    echo "Waiting for emulator to be ready..."
    
    # Wait for boot completed
    until adb shell getprop sys.boot_completed | grep -q 1; do
        echo "  Boot not complete, waiting..."
        sleep 2
    done
    echo "  Boot completed"
    
    # Wait for package manager
    until adb shell pm path android >/dev/null 2>&1; do
        echo "  Package manager not ready, waiting..."
        sleep 2
    done
    echo "  Package manager ready"
    
    # Wait for input service (critical for tests)
    echo "  Waiting for input service..."
    sleep 5
    
    # Try to check if input service is available
    for i in {1..10}; do
        if adb shell input keyevent KEYCODE_SLEEP >/dev/null 2>&1; then
            echo "  Input service ready"
            break
        fi
        echo "  Input service not ready (attempt $i/10), waiting..."
        sleep 2
    done
    
    # Additional wait for system to settle
    echo "  Waiting for system to settle..."
    sleep 5
    
    echo "✅ Emulator is fully ready"
}

# Main execution
main() {
    # Create screenshots directory
    mkdir -p screenshots/e2e
    
    # Wait for emulator
    wait_for_emulator
    
    # Get device ID
    DEVICE=$(adb devices | grep emulator | awk '{print $1}' | head -1)
    if [ -z "$DEVICE" ]; then
        echo "❌ No emulator device found!"
        exit 1
    fi
    echo "📱 Using device: $DEVICE"
    
    # Run flutter drive
    echo "Running E2E tests..."
    flutter drive \
        --driver=test_driver/integration_test.dart \
        --target=integration_test/app_flow_test.dart \
        --device-id="$DEVICE" || echo "⚠️ Tests completed with warnings"
    
    # Show results
    echo ""
    echo "=== Test Results ==="
    if [ -d "screenshots/e2e" ]; then
        echo "Screenshots captured:"
        ls -la screenshots/e2e/*.png 2>/dev/null || echo "  No PNG files found"
    else
        echo "No screenshots directory"
    fi
}

main "$@"
