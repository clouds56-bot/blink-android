#!/bin/bash
# Setup test environment for integration tests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🔧 Setting up Blink Android test environment..."

# Create test data directory
mkdir -p "$PROJECT_ROOT/test_data"

# Create test files
echo "Hello from Blink Android!" > "$PROJECT_ROOT/test_data/hello.txt"
echo "This is a test file for SFTP operations." > "$PROJECT_ROOT/test_data/test_file.txt"
echo "Line 1
Line 2
Line 3" > "$PROJECT_ROOT/test_data/multiline.txt"

# Create test directories
mkdir -p "$PROJECT_ROOT/test_data/test_folder"
mkdir -p "$PROJECT_ROOT/test_data/deeply/nested/folder"
echo "Nested file content" > "$PROJECT_ROOT/test_data/deeply/nested/folder/file.txt"

# Create SSH keys for testing
mkdir -p "$PROJECT_ROOT/test_keys"
ssh-keygen -t rsa -b 2048 -f "$PROJECT_ROOT/test_keys/id_rsa" -N "" -q
cp "$PROJECT_ROOT/test_keys/id_rsa.pub" "$PROJECT_ROOT/test_keys/authorized_keys"

echo "✅ Test environment setup complete!"
echo ""
echo "Test files created in: $PROJECT_ROOT/test_data"
echo "SSH keys created in: $PROJECT_ROOT/test_keys"
echo ""
echo "To start the SSH server, run:"
echo "  docker-compose -f docker-compose.test.yml up -d"
echo ""
echo "SSH server will be available at:"
echo "  Host: localhost"
echo "  Port: 2222"
echo "  Username: testuser"
echo "  Password: testpass"
