#!/usr/bin/env python3
"""
E2E Test Runner with Screenshot Capture
Runs Flutter integration tests and captures screenshots via ADB

IMPORTANT: This script requires a display surface for rendering.
- Local: Start emulator WITHOUT -no-window flag, or use Xvfb
- CI: Use reactivecircus/android-emulator-runner which provides virtual framebuffer

For local testing with display:
  flutter emulators --launch test_emulator  # WITHOUT -no-window
  python3 scripts/run_e2e_screenshots.py
"""

import subprocess
import sys
import time
import os
import re
from pathlib import Path

PROJECT_DIR = Path(__file__).parent.parent
SCREENSHOTS_DIR = PROJECT_DIR / "screenshots" / "e2e"
def get_android_device():
    """Get the first available Android device/emulator"""
    # If device is specified in env, use it
    if os.environ.get("ANDROID_DEVICE"):
        return os.environ["ANDROID_DEVICE"]
    
    # Try to find device via adb
    result = subprocess.run(
        ["adb", "devices"],
        capture_output=True,
        text=True
    )
    
    for line in result.stdout.split("\n"):
        if "\tdevice" in line:
            return line.split("\t")[0]
    
    # Default
    return "emulator-5554"

DEVICE = get_android_device()

def setup_screenshots():
    """Create screenshots directory and clean old files"""
    SCREENSHOTS_DIR.mkdir(parents=True, exist_ok=True)
    for f in SCREENSHOTS_DIR.glob("*.png"):
        f.unlink()
    print(f"📸 Screenshots dir: {SCREENSHOTS_DIR}")

def capture_screenshot(name: str, counter: list):
    """Capture screenshot via ADB"""
    counter[0] += 1
    filename = f"{counter[0]:02d}_{name}.png"
    filepath = SCREENSHOTS_DIR / filename
    
    result = subprocess.run(
        ["adb", "-s", DEVICE, "exec-out", "screencap", "-p"],
        capture_output=True
    )
    
    if result.returncode == 0 and len(result.stdout) > 0:
        filepath.write_bytes(result.stdout)
        print(f"  📸 Saved: {filename}")
    else:
        print(f"  ⚠️ Failed: {filename}")

def run_test_with_screenshots():
    """Run Flutter test and capture screenshots"""
    print(f"\n🚀 Running E2E tests on {DEVICE}\n")
    
    setup_screenshots()
    counter = [0]
    
    # Start Flutter test
    process = subprocess.Popen(
        ["flutter", "test", "integration_test/app_flow_test.dart", "-d", DEVICE],
        cwd=PROJECT_DIR,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1
    )
    
    # Track test state for screenshots
    last_screenshot_time = time.time()
    
    # Read output line by line
    for line in iter(process.stdout.readline, ''):
        print(line, end='')
        
        # Capture screenshot when test indicates
        if "📸 STEP:" in line:
            match = re.search(r"📸 STEP: (\w+)", line)
            if match:
                step_name = match.group(1)
                time.sleep(0.3)  # Let UI settle
                capture_screenshot(step_name, counter)
                last_screenshot_time = time.time()
    
    process.wait()
    
    # Final screenshot
    time.sleep(0.5)
    capture_screenshot("final", counter)
    
    print(f"\n📸 Screenshots saved to: {SCREENSHOTS_DIR}")
    return process.returncode

def main():
    # Check device is connected (try multiple device names)
    result = subprocess.run(
        ["flutter", "devices", "--device-timeout", "30"],
        cwd=PROJECT_DIR,
        capture_output=True,
        text=True,
        env={**os.environ, "PATH": os.environ.get("PATH", "")}
    )
    
    # Check for any emulator
    if "emulator" not in result.stdout and "android" not in result.stdout.lower():
        print(f"❌ No Android device found!")
        print("Available devices:")
        print(result.stdout)
        return 1
    
    print(f"📱 Device check passed")
    
    # Run tests
    return_code = run_test_with_screenshots()
    
    if return_code == 0:
        print("\n✅ All tests passed!")
    else:
        print(f"\n❌ Tests failed with code {return_code}")
    
    return return_code

if __name__ == "__main__":
    sys.exit(main())
