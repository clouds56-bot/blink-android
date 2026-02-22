# Blink Android - Quick Start

## What's New

✅ **Full SSH Terminal** - Connect to any SSH server with password or key authentication
✅ **Private Key Import** - Import .pem/.key files directly from your device
✅ **Secure Credential Storage** - Passwords and keys encrypted in secure storage
✅ **Real Terminal I/O** - Interactive terminal with auto-scroll

## Installation

### 1. Install Flutter (if not already installed)
```bash
# Download Flutter SDK from https://docs.flutter.dev/get-started/install

# Verify installation
flutter doctor

# Accept Android licenses
flutter doctor --android-licenses
```

### 2. Install Dependencies
```bash
cd blink_android
flutter pub get
```

### 3. Run the App
```bash
# Connect an Android device via USB or start an emulator
flutter devices

# Run on connected device
flutter run

# Or build APK
flutter build apk --release
```

## Usage Guide

### Adding a Connection

#### Method 1: Password Authentication
1. Tap **+** on home screen
2. Enter connection details:
   - Name: `My Server`
   - Host: `192.168.1.100` or `example.com`
   - Port: `22` (or custom)
   - Username: `root` or your username
   - Password: `your-password`
3. Tap **Save Connection**

#### Method 2: Private Key Authentication
1. Tap **+** on home screen
2. Enter connection details (name, host, port, username)
3. Tap **Import Private Key**
4. Select your `.pem` or `.key` file from device storage
5. Verify key is shown with green checkmark
6. Tap **Save Connection**

### Using the Terminal

1. **Connect**: Tap any connection in the list
2. **Wait**: Connection status banner will appear, then clear when connected
3. **Type Commands**: Use the bottom input field
4. **Press Enter**: Execute the command
5. **View Output**: Terminal output appears in the black area

### Terminal Features

- **Auto-scroll**: Output automatically scrolls to show latest
- **Reconnect**: Tap refresh icon to reconnect without going back
- **Error Display**: Connection errors show in red at the top
- **Keyboard Focus**: Automatically focuses when connected

### Managing Connections

#### Favorite Connections
- Tap star icon to mark as favorite
- Favorites appear at top of home screen

#### Edit Connection
- Tap ⋮ (menu) on connection
- Select "Edit"
- Modify details and save

#### Delete Connection
- Tap ⋮ (menu) on connection
- Select "Delete"
- Confirm deletion

## Common Commands to Try

```bash
# List files
ls -la

# Current directory
pwd

# System info
uname -a

# Disk usage
df -h

# Memory usage
free -h

# Process list
ps aux

# Test connection
echo "Hello from Blink Android!"
```

## Troubleshooting

### "Command not found: flutter"
- Flutter SDK is not installed or not in your PATH
- Install Flutter from https://docs.flutter.dev/get-started/install

### "No devices found"
- Connect an Android device via USB
- Or start an Android emulator
- Run `flutter devices` to see available devices

### Connection Failed
- Check host and port are correct
- Verify username
- Ensure password or private key is correct
- Check firewall rules on server
- Verify SSH server is running on target

### "Authentication failed"
- For password: Verify password is correct
- For key: Ensure key format is PEM
- Check key permissions on server (usually requires `chmod 600 ~/.ssh/authorized_keys`)

### Terminal Output Looks Strange
- Some apps require VT100 emulation (not fully implemented)
- Try simpler commands like `ls`, `pwd`, `cat`

### Cannot Import Private Key
- Ensure file is in PEM format (starts with `-----BEGIN`)
- File must have .pem, .key, or similar extension
- Check file is accessible from the app

## File Formats

### PEM Private Key Format
```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA...
...
-----END RSA PRIVATE KEY-----
```

### ED25519 Key Format
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjE...
...
-----END OPENSSH PRIVATE KEY-----
```

## Security Notes

- ✅ Passwords stored securely with flutter_secure_storage
- ✅ Private keys encrypted in device keychain/keystore
- ✅ Uses standard SSH protocol (dartssh2)
- ⚠️ Host keys are not verified (future enhancement)
- ⚠️ Keep your device secure with lock screen

## Next Steps

1. Test with your servers
2. Import your SSH keys
3. Try common commands
4. Report issues and request features

## Getting Help

- Check CHANGES.md for technical details
- Review the source code in `lib/screens/`
- SSH implementation: `lib/screens/terminal_screen.dart`

---

**Happy SSH-ing! 🚀**
