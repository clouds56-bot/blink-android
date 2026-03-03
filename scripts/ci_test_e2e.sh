#!/bin/bash
# CI E2E Test Runner Script
# Waits for Android system to be fully ready before running tests

set -e

echo "=== E2E Test Runner ==="

# Wait for emulator to be fully ready
wait_for_emulator() {
    echo "Waiting for emulator to be ready..."
    
    local timeout=120
    local elapsed=0
    
    # Wait for boot completed with timeout
    while [ $elapsed -lt $timeout ]; do
        if adb shell getprop sys.boot_completed 2>/dev/null | grep -q 1; then
            echo "  ✅ Boot completed (${elapsed}s)"
            break
        fi
        echo "  Boot not complete (${elapsed}s/${timeout}s), waiting..."
        sleep 5
        elapsed=$((elapsed + 5))
    done
    
    if [ $elapsed -ge $timeout ]; then
        echo "❌ Boot timeout after ${timeout}s"
        exit 1
    fi
    
    # Wait for package manager with timeout
    elapsed=0
    timeout=60
    while [ $elapsed -lt $timeout ]; do
        if adb shell pm path android >/dev/null 2>&1; then
            echo "  ✅ Package manager ready (${elapsed}s)"
            break
        fi
        echo "  Package manager not ready (${elapsed}s/${timeout}s), waiting..."
        sleep 2
        elapsed=$((elapsed + 2))
    done
    
    if [ $elapsed -ge $timeout ]; then
        echo "❌ Package manager timeout"
        exit 1
    fi
    
    # Wait for input service with timeout
    echo "  Waiting for input service..."
    elapsed=0
    timeout=60
    while [ $elapsed -lt $timeout ]; do
        if adb shell input keyevent KEYCODE_SLEEP >/dev/null 2>&1; then
            echo "  ✅ Input service ready (${elapsed}s)"
            break
        fi
        echo "  Input service not ready (${elapsed}s/${timeout}s), waiting..."
        sleep 2
        elapsed=$((elapsed + 2))
    done
    
    # Additional settle time
    echo "  Waiting for system to settle (5s)..."
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
    
    # Run integration test via flutter drive for proper screenshot capture
    echo "Running E2E tests via flutter drive (10 min timeout)..."
    timeout 600 flutter drive \
        --driver=test_driver/integration_test.dart \
        --target=integration_test/app_flow_test.dart \
        -d "$DEVICE" || {
            echo "⚠️ Tests exited with non-zero code: $?"
        }
    
    echo ""
    echo "=== Test Results ==="
    
    # List final screenshots
    echo ""
    echo "Screenshots in screenshots/e2e/:"
    ls -la screenshots/e2e/*.png 2>/dev/null || echo "  No PNG files found"
    
    # Check for integration test response data
    if [ -f "build/integration_response_data.json" ]; then
        echo "📄 Found response data: build/integration_response_data.json"
    fi
}

main "$@"
