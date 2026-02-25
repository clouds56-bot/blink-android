#!/bin/bash
# Run app flow tests (no Docker required)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================"
echo "   Blink Android App Flow Tests"
echo "   (No Docker Required)"
echo "======================================${NC}"
echo ""

cd "$PROJECT_ROOT"

# Check if flutter is available
if ! command -v flutter &> /dev/null; then
  echo -e "${RED}❌ Flutter not found${NC}"
  echo "Please install Flutter and add it to your PATH"
  exit 1
fi

# Get dependencies
echo -e "${YELLOW}📥 Getting dependencies...${NC}"
flutter pub get

echo ""
echo -e "${YELLOW}📱 Checking for Android emulator...${NC}"

# List emulators
flutter emulators

echo ""
echo -e "${BLUE}Note: Make sure you have an Android emulator or device running!${NC}"
echo ""
echo -e "${BLUE}To start the emulator manually:${NC}"
echo -e "  flutter emulators"
echo -e "  flutter emulators --launch <emulator_id>"
echo ""
read -p "Press Enter when emulator is ready or Ctrl+C to cancel..."

# Run app flow tests
echo ""
echo -e "${YELLOW}🧪 Running app flow tests...${NC}"
flutter test integration_test/app_flow_test.dart

echo ""
echo -e "${GREEN}======================================"
echo "   Tests Complete!"
echo "======================================${NC}"
echo ""
echo "Screenshots saved to: /tmp/blink_android_app_flow/"
echo ""
echo -e "${GREEN}Done!${NC}"
