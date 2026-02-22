Implement full SSH terminal functionality

## Features Added

### File Picker for Private Keys
- Import .pem/.key files from device storage
- Visual feedback with checkmark indicator
- Clear button to remove imported keys
- Error handling with user-friendly messages

### Full SSH Connection Implementation
- Complete SSH client using dartssh2
- Password authentication with secure storage integration
- Private key authentication support (PEM format)
- PTY (pseudo-terminal) session creation
- Real-time output streaming
- Connection status indicators (connecting/error)
- Reconnect functionality
- Proper resource cleanup

### Terminal I/O
- Interactive command input
- Real-time output display with auto-scroll
- Monospace font styling
- Error highlighting in red
- Special key support (arrows, tab, Ctrl+C)
- Disabled input when disconnected

## Technical Changes

- Added `file_picker: ^8.1.6` dependency
- Complete rewrite of terminal_screen.dart with full SSH implementation
- Implemented _importPrivateKey() in add_connection_screen.dart
- Integrated with ConnectionService for secure password retrieval
- Added stream handling for terminal output

## Dependencies
- dartssh2 (now fully utilized)
- flutter_secure_storage (for credential storage)
- provider (state management)
- file_picker (new - for key import)

## Documentation
- Added CHANGES.md with technical details
- Added QUICKSTART.md with user guide
- Added IMPLEMENTATION_COMPLETE.md as summary
