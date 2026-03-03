#!/usr/bin/env python3
"""
E2E Test Runner with Screenshot Capture
Launches app via flutter run and captures screenshots via ADB
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
    result = subprocess.run(
        ["adb", "devices"],
        capture_output=True,
        text=True
    )
    
    for line in result.stdout.split("\n"):
        if "\tdevice" in line:
            return line.split("\t")[0]
    
    return None

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
        return True
    else:
        print(f"  ⚠️ Failed: {filename}")
        return False

def tap_screen(x: int, y: int):
    """Tap on screen at coordinates"""
    subprocess.run(
        ["adb", "-s", DEVICE, "shell", "input", "tap", str(x), str(y)],
        capture_output=True
    )
    time.sleep(0.5)

def type_text(text: str):
    """Type text using ADB"""
    # Replace spaces with %s for ADB
    safe_text = text.replace(" ", "%s")
    subprocess.run(
        ["adb", "-s", DEVICE, "shell", "input", "text", safe_text],
        capture_output=True
    )
    time.sleep(0.3)

def press_back():
    """Press back button"""
    subprocess.run(
        ["adb", "-s", DEVICE, "shell", "input", "keyevent", "KEYCODE_BACK"],
        capture_output=True
    )
    time.sleep(0.5)

def press_tab():
    """Press tab to move to next field"""
    subprocess.run(
        ["adb", "-s", DEVICE, "shell", "input", "keyevent", "KEYCODE_TAB"],
        capture_output=True
    )
    time.sleep(0.3)

def run_app_flow_test():
    """Run app flow test with manual ADB control"""
    print("\n🚀 Running App Flow E2E Test")
    print("=" * 50)
    
    counter = [0]
    
    # Launch app
    print("📱 Launching Blink Android...")
    subprocess.run(
        ["adb", "-s", DEVICE, "shell", "am", "start", "-n", 
         "com.clouds56.blink_android/.MainActivity"],
        capture_output=True
    )
    time.sleep(3)  # Wait for app to fully render
    
    # Screenshot 1: Home screen (empty state)
    print("Step 1: Home screen")
    capture_screenshot("home_screen", counter)
    
    # Tap the add button (FAB typically in bottom right or top right)
    print("Step 2: Tapping add button...")
    # Try top-right first (app bar action button)
    tap_screen(1000, 200)  # Approximate position for app bar action
    time.sleep(1)
    
    # Screenshot 2: Add connection screen
    print("Step 3: Add connection screen")
    capture_screenshot("add_connection_screen", counter)
    
    # Fill form
    print("Step 4: Filling form...")
    # Tap on first field (name)
    tap_screen(540, 400)
    type_text("Test_Connection")
    press_tab()
    
    # Host field
    type_text("192.168.1.1")
    press_tab()
    
    # Port field
    type_text("22")
    press_tab()
    
    # Username field
    type_text("testuser")
    press_tab()
    
    # Password field
    type_text("testpass")
    
    time.sleep(1)
    
    # Screenshot 3: Form filled
    print("Step 5: Form filled")
    capture_screenshot("form_filled", counter)
    
    # Go back
    print("Step 6: Going back...")
    press_back()
    time.sleep(1)
    
    # Screenshot 4: Back to home
    print("Step 7: Back to home")
    capture_screenshot("back_to_home", counter)
    
    print("\n✅ App flow test completed!")
    return counter[0]

def main():
    global DEVICE
    
    # Check device
    DEVICE = get_android_device()
    if not DEVICE:
        print("❌ No Android device found!")
        return 1
    
    print(f"📱 Device: {DEVICE}")
    
    # Setup
    setup_screenshots()
    
    # Run test
    screenshot_count = run_app_flow_test()
    
    print(f"\n📸 {screenshot_count} screenshots saved to: {SCREENSHOTS_DIR}")
    
    # List screenshots
    for f in sorted(SCREENSHOTS_DIR.glob("*.png")):
        print(f"  - {f.name}")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
