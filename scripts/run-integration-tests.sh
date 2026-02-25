#!/bin/bash
# Run integration tests with Docker SSH server

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
echo "   Blink Android Integration Tests"
echo "======================================${NC}"
echo ""

# Step 1: Setup test environment
echo -e "${YELLOW}📦 Step 1: Setting up test environment...${NC}"
"$SCRIPT_DIR/setup-test-env.sh"
echo ""

# Step 2: Start Docker containers
echo -e "${YELLOW}🐳 Step 2: Starting SSH server containers...${NC}"
cd "$PROJECT_ROOT"
docker-compose -f docker-compose.test.yml up -d

echo ""
echo -e "${YELLOW}⏳ Waiting for SSH server to be ready...${NC}"
sleep 10

# Check if containers are running
if docker ps | grep -q "blink-android-ssh-test"; then
  echo -e "${GREEN}✅ SSH server is running${NC}"
  echo "   Host: localhost"
  echo "   Port: 2222"
  echo "   Username: testuser"
  echo "   Password: testpass"
else
  echo -e "${RED}❌ Failed to start SSH server${NC}"
  echo "Check logs with: docker-compose -f docker-compose.test.yml logs"
  exit 1
fi

echo ""
echo -e "${YELLOW}📱 Step 3: Running integration tests...${NC}"
echo ""
echo -e "${BLUE}Note: Make sure you have an Android emulator or device running!${NC}"
echo ""
echo -e "${BLUE}To start the emulator manually:${NC}"
echo -e "  flutter emulators"
echo -e "  flutter emulators --launch <emulator_id>"
echo ""
read -p "Press Enter when emulator is ready or Ctrl+C to cancel..."

# Get dependencies
echo ""
echo -e "${YELLOW}📥 Getting dependencies...${NC}"
flutter pub get

# Run integration tests
echo ""
echo -e "${YELLOW}🧪 Running integration tests...${NC}"
flutter test integration_test/ssh_connection_test.dart --dart-define=FLUTTER_TEST=true

echo ""
echo -e "${GREEN}======================================"
echo "   Integration Tests Complete!"
echo "======================================${NC}"
echo ""
echo "Screenshots saved to: /tmp/blink_android_test_screenshots"
echo ""

# Ask if user wants to stop containers
echo -e "${YELLOW}Stop Docker containers? (y/n)${NC}"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo ""
  echo -e "${YELLOW}🛑 Stopping containers...${NC}"
  docker-compose -f docker-compose.test.yml down
  echo -e "${GREEN}✅ Containers stopped${NC}"
else
  echo ""
  echo -e "${YELLOW}Containers still running. Stop them with:${NC}"
  echo "  docker-compose -f docker-compose.test.yml down"
fi

echo ""
echo -e "${GREEN}Done!${NC}"
