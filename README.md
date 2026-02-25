# Blink Android

A modern SSH client and terminal emulator for Android, built with Flutter.

## Features

### ✅ Fully Implemented

- **SSH Terminal**
  - Full SSH connection using dartssh2
  - Password authentication with secure storage
  - Private key authentication (PEM format)
  - Import private keys from device
  - Real-time terminal I/O with streaming output
  - ANSI escape code support (xterm emulator)
  - Reconnect functionality
  - Connection status and error handling

- **SFTP File Explorer**
  - Browse remote file systems
  - Navigate directories (tap to enter, back button to go up)
  - File and folder management:
    - Upload files from device
    - Download files to memory
    - Delete files and directories
    - Rename files and directories
    - Create new folders
  - File viewer for text and image files
  - Pull-to-refresh
  - File count display
  - Haptic feedback for interactions

- **Connection Management**
  - Add, edit, delete SSH connections
  - Favorites list
  - Recent connections
  - Secure credential storage (passwords in Android Keystore)
  - Private key import from device storage

## Status

**Version:** 1.0.0+1
**Status:** Production Ready ✅
**Tests:** All tests passing (18 unit tests + widget tests)

## Getting Started

### Prerequisites
- Flutter SDK 3.11.0 or higher
- Android SDK (for Android builds)
- A running SSH server to connect to

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/blink_android.git
cd blink_android

# Install dependencies
flutter pub get

# Run the app (connect device/emulator first)
flutter run
```

### Building for Release

```bash
# APK
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release
```

## Usage

### Adding an SSH Connection

1. Tap the "+" button on the home screen
2. Fill in connection details:
   - **Name**: Display name for the connection
   - **Host**: Server hostname or IP
   - **Port**: SSH port (default: 22)
   - **Username**: SSH username
3. Choose authentication method:
   - **Password**: Enter password (stored securely)
   - **Private Key**: Tap "Import Private Key" and select `.pem` or `.key` file
4. Tap "Save Connection"

### Using the Terminal

1. Tap a saved connection to connect
2. Wait for the connection banner to clear
3. Type commands in the input field and press Enter
4. Terminal output displays in real-time
5. Use the reconnect button (refresh icon) to reconnect

### Using SFTP File Explorer

1. Connect to an SSH server in the terminal
2. Tap the folder icon in the app bar
3. Browse files:
   - Tap directories to navigate into them
   - Use the back arrow to go to parent directory
   - Use the home icon to go to root
4. File actions (long-press):
   - **Download**: Download file to memory
   - **Delete**: Delete with confirmation
   - **Rename**: Rename file/directory
5. Use the upload button to upload files from device
6. Use the create folder button to make new directories

## Tech Stack

| Package | Version | Purpose |
|---------|---------|---------|
| flutter | sdk | UI framework |
| dartssh2 | ^2.8.6 | SSH client and protocol |
| flutter_secure_storage | ^9.2.2 | Secure credential storage |
| provider | ^6.1.2 | State management |
| xterm | ^4.0.0 | Terminal emulator with ANSI support |
| file_picker | ^8.1.6 | File selection for keys/uploads |
| path_provider | ^2.1.4 | File paths |
| uuid | ^4.5.1 | Unique IDs |
| shared_preferences | ^2.3.3 | Connection metadata |

## Architecture

```
lib/
├── main.dart                          # Entry point + providers
├── models/
│   └── ssh_connection.dart           # Connection model
├── services/
│   ├── connection_service.dart       # Data persistence + secure storage
│   └── sftp_service.dart             # SFTP operations
├── screens/
│   ├── home_screen.dart              # Connection list
│   ├── add_connection_screen.dart    # Add/edit form + file picker
│   ├── terminal_screen.dart          # Terminal + SSH client
│   ├── file_explorer_screen.dart     # SFTP file browser
│   └── file_viewer_screen.dart       # Text and image viewer
└── utils/
    └── ansi_formatter.dart           # ANSI code utilities
```

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/services/sftp_service_test.dart
```

**Test Coverage:**
- 18 unit tests for SFTP service
- Widget tests for all screens
- All tests passing ✅

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add/update tests
5. Submit a pull request

## Known Limitations

1. **VT100/VT220 Emulation**: Basic ANSI support is implemented, but complex terminal applications may have display issues
2. **Host Key Verification**: Host keys are not currently verified or stored
3. **File Downloads**: Downloads currently go to memory only (device filesystem integration planned)
4. **Batch Operations**: Multiple file selection not yet implemented

## Future Enhancements

- [ ] Host key verification and storage
- [ ] Device filesystem integration for downloads
- [ ] Multiple file selection for batch operations
- [ ] Progress indicators for file transfers
- [ ] Background file transfers
- [ ] Transfer queue management
- [ ] Terminal font size adjustment
- [ ] Copy/paste from terminal
- [ ] Save terminal output to file
- [ ] Multiple terminal sessions (tabs)
- [ ] SSH tunneling support
- [ ] Port forwarding
- [ ] X11 forwarding
- [ ] Search/filter in file explorer
- [ ] Sort options (name, size, date)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues, questions, or feature requests, please open an issue on GitHub.

---

**Built with ❤️ using Flutter**
