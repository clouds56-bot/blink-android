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
    
    # Check pre-built APK exists
    APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
    if [ ! -f "$APK_PATH" ]; then
        echo "❌ Pre-built APK not found at $APK_PATH"
        exit 1
    fi
    echo "📦 Using pre-built APK: $APK_PATH ($(ls -lh $APK_PATH | awk '{print $5}'))"
    
    # Run flutter drive with pre-built APK and timeout
    echo "Running E2E tests (10 min timeout)..."
    timeout 600 flutter drive \
        --driver=test_driver/integration_test.dart \
        --target=integration_test/app_flow_test.dart \
        --use-application-binary="$APK_PATH" \
        --device-id="$DEVICE"
    
    DRIVE_EXIT=$?
    if [ $DRIVE_EXIT -eq 124 ]; then
        echo "❌ Tests timed out after 10 minutes"
        exit 1
    elif [ $DRIVE_EXIT -ne 0 ]; then
        echo "⚠️ Tests completed with exit code: $DRIVE_EXIT"
    else
        echo "✅ Tests completed successfully"
    fi
    
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
