# Integration Tests for Blink Android

End-to-end testing suite for Blink Android with Docker-based SSH server support and app flow testing.

## Overview

This integration test suite provides:

1. **App Flow Tests** - Run without Docker, test UI and navigation
2. **SSH Connection Tests** - Full end-to-end with Docker SSH server
3. **Screenshot Capture** - Visual verification of each test step

## Quick Start (No Docker Required)

### Run App Flow Tests

```bash
# Start Android emulator
flutter emulators --launch <emulator_id>

# Run app flow tests
flutter test integration_test/app_flow_test.dart
```

This tests:
- App navigation
- Form validation
- UI component visibility
- User interaction flow

Screenshots saved to: `/tmp/blink_android_app_flow/`

---

## Full Integration Tests (With Docker)

### Prerequisites

1. **Docker and Docker Compose** installed
2. **Flutter SDK** installed
3. **Android emulator or device** running

### Setup

#### 1. Start the SSH Test Server

```bash
# Start SSH server
docker compose -f docker-compose.test.yml up -d

# Or use the helper script
./docker/test-ssh-server.sh start
```

The SSH server will be available at:
- **Host:** `localhost` (or `10.0.2.2` from Android emulator)
- **Port:** `2222`
- **Username:** `testuser`
- **Password:** `testpass`

#### 2. Setup Test Environment

```bash
# Create test files and SSH keys
./scripts/setup-test-env.sh
```

This creates:
- `test_data/` directory with sample files
- `test_keys/` directory with SSH key pair

#### 3. Start Android Emulator

```bash
# List available emulators
flutter emulators

# Launch an emulator
flutter emulators --launch <emulator_id>
```

#### 4. Run SSH Integration Tests

```bash
# Run SSH connection tests
flutter test integration_test/ssh_connection_test.dart
```

### Screenshots

After running tests, screenshots are saved to:
```
/tmp/blink_android_test_screenshots/
```

---

## What's Tested

### App Flow Tests (`app_flow_test.dart`)

| Step | Screenshot | Description |
|------|-----------|-------------|
| 1 | `01_home_screen.png` | Initial home screen |
| 2 | `02_add_connection_screen.png` | Add connection form |
| 3 | `03_form_filled.png` | Form filled with test data |
| 4 | `04_back_to_home.png` | Return to home |
| 5 | `05_empty_state.png` | Empty state UI |

### SSH Connection Tests (`ssh_connection_test.dart`)

| Step | Screenshot | Description |
|------|-----------|-------------|
| 1 | `01_home_screen.png` | Initial home screen |
| 2 | `02_add_connection_screen.png` | Add connection form |
| 3 | `03_form_filled.png` | Form filled |
| 4 | `04_connection_added.png` | Connection in list |
| 5 | `05_terminal_connecting.png` | Connecting to SSH |
| 6 | `06_terminal_connected.png` | Terminal ready |
| 7 | `07_command_entered.png` | Command typed |
| 8 | `08_command_output.png` | Command output |
| 9 | `09_pwd_command.png` | PWD command |
| 10 | `10_file_explorer.png` | SFTP browser |
| 11 | `11_back_to_home.png` | Back to home |

---

## Docker Setup

### SSH Server Container

```yaml
services:
  ssh-server:
    image: panubo/sshd:latest
    ports:
      - "2222:22"
    environment:
      SSH_USERS: "testuser:testpass:1000:1000"
```

### SFTP Server Container

```yaml
services:
  sftp-server:
    image: atmoz/sftp:latest
    ports:
      - "2223:22"
    command: "testuser:testpass:1001"
```

---

## Test Files

Created in `test_data/`:

```
test_data/
├── hello.txt              # Simple text file
├── test_file.txt          # Test content
├── multiline.txt          # Multiple lines
├── test_folder/           # Test directory
└── deeply/
    └── nested/
        └── folder/
            └── file.txt   # Nested file
```

---

## Scripts Reference

| Script | Purpose |
|--------|---------|
| `scripts/setup-test-env.sh` | Create test files and SSH keys |
| `scripts/run-integration-tests.sh` | Full test automation |
| `docker/test-ssh-server.sh` | Start/stop SSH server |
| `integration_test/app_flow_test.dart` | App flow tests (no Docker) |
| `integration_test/ssh_connection_test.dart` | Full SSH tests (with Docker) |

---

## Manual Testing

### Without Docker

1. Run app: `flutter run`
2. Navigate through UI
3. Test forms and buttons

### With Docker

1. Start server: `docker compose -f docker-compose.test.yml up -d`
2. Run app: `flutter run`
3. Add connection:
   - Name: `Test Server`
   - Host: `10.0.2.2` (emulator) or `localhost`
   - Port: `2222`
   - Username: `testuser`
   - Password: `testpass`

---

## Troubleshooting

### Docker Not Available

Use the app flow tests instead:
```bash
flutter test integration_test/app_flow_test.dart
```

### Emulator Cannot Connect to SSH

The Android emulator uses a special IP to access the host:
- Use `10.0.2.2` instead of `localhost`

### Tests Timeout

- Increase timeout values in the test file
- Check emulator network settings
- Verify SSH server is responding: `nc -zv localhost 2222`

---

## CI/CD Integration

### Without Docker (Faster)

```yaml
name: App Flow Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - name: Run app flow tests
        run: flutter test integration_test/app_flow_test.dart
```

### With Docker (Full Integration)

```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - name: Start SSH server
        run: docker compose -f docker-compose.test.yml up -d
      - name: Run tests
        run: flutter test integration_test/ssh_connection_test.dart
```

---

## SSH Server Credentials

### For Testing
- **Host:** `10.0.2.2` (emulator) or `localhost` (host)
- **Port:** `2222`
- **Username:** `testuser`
- **Password:** `testpass`

### SFTP Server
- **Host:** Same as SSH
- **Port:** `2223`
- **Username:** `testuser`
- **Password:** `testpass`

---

## Future Enhancements

- [ ] Add performance benchmarks
- [ ] Test multiple SSH servers
- [ ] Test error scenarios
- [ ] Test file upload/download
- [ ] Test private key authentication
- [ ] Add network latency simulation
- [ ] Test on real devices
- [ ] Video recording of tests

---

## Resources

- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Docker Compose](https://docs.docker.com/compose/)
- [SSH Docker Image](https://hub.docker.com/r/panubo/sshd)
