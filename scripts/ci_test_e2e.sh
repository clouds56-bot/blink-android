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
    echo "  Waiting for system to settle (10s)..."
    sleep 10
    
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
    
    # Run integration test with flutter drive so screenshot data is returned
    # to test_driver/integration_test.dart responseDataCallback.
    echo "Running E2E tests (15 min timeout)..."
    set +e
    timeout 900 flutter drive \
        --driver=test_driver/integration_test.dart \
        --target=integration_test/app_flow_test.dart \
        --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk \
        -d "$DEVICE"
    TEST_EXIT_CODE=$?
    set -e

    if [ $TEST_EXIT_CODE -ne 0 ]; then
        echo "⚠️ Tests exited with non-zero code: $TEST_EXIT_CODE"
    fi
    
    echo ""
    echo "=== Test Results ==="
    
    # Copy screenshots from test outputs to our directory
    if [ -d "build/test_outputs" ]; then
        echo "Found test outputs:"
        ls -la build/test_outputs/ 2>/dev/null || true
        
        # Copy any screenshots
        if ls build/test_outputs/*.png 2>/dev/null; then
            cp build/test_outputs/*.png screenshots/e2e/ 2>/dev/null || true
            echo "📸 Screenshots copied to screenshots/e2e/"
        fi
    fi
    
    # Check for integration test response data
    if [ -f "build/integration_response_data.json" ]; then
        echo "📄 Found response data: build/integration_response_data.json"
    fi
    
    # List final screenshots
    echo ""
    echo "Screenshots in screenshots/e2e/:"
    ls -la screenshots/e2e/*.png 2>/dev/null || echo "  No PNG files found"

    exit $TEST_EXIT_CODE
}

main "$@"
