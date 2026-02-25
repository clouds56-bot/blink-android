# AGENTS.md - blink-android

Project conventions and workflows for AI assistants working on this Flutter SSH client app.

## Current Project Status

**Status:** Production Ready ✅
**Version:** 1.0.0+1
**Core Features:** All implemented and tested

### Implemented Features
- ✅ SSH Terminal with dartssh2
- ✅ Password and private key authentication
- ✅ SFTP file explorer
- ✅ File viewer (text and images)
- ✅ Connection management
- ✅ Secure credential storage
- ✅ Real-time terminal I/O with ANSI support
- ✅ 18 unit tests passing
- ✅ Integration tests (app flow + SSH connection with Docker)

### Documentation Files
- `README.md` - User guide and project overview
- `PROJECT_STATUS.md` - Current status and feature overview
- `SFTP_MVP_SUMMARY.md` - SFTP implementation details
- `IMPLEMENTATION_COMPLETE.md` - Feature completion summary
- `CHANGES.md` - Technical change log
- `QUICKSTART.md` - Quick start guide
- `AGENTS.md` - This file (development guidelines)
- `INTEGRATION_TESTS.md` - Integration test documentation
- `INTEGRATION_TEST_IMPLEMENTATION.md` - Implementation summary

---

## Core Principles

### 0. Collaborate First (Team Projects)
- **ALWAYS communicate before making large changes**
- Check if someone else is working on related code
- Create issues for features and discuss before implementing
- Ask for review early, not just at the end
- **Sync frequently** with main branch to avoid conflicts

### 1. Test-First Development
- **ALWAYS write tests before implementing features**
- Start with failing tests that describe expected behavior
- Only write production code to make tests pass
- Tests are the contract - they define what the code should do

### 2. Run Tests After Every Change
- **ALWAYS run tests after any code change**
- No change is complete without test verification
- Run the full test suite: `flutter test`
- Run specific test file: `flutter test test/feature_test.dart`

### 3. GitHub PR Workflow
- **ALWAYS use Pull Requests for features and bug fixes**
- Never push directly to `main` branch
- Create feature branches: `git checkout -b feature/your-feature` or `fix/your-fix`
- PRs must pass CI before merge
- Include tests in your PR
- **Get at least one approval** before merging
- **Don't merge your own PR** unless agreed with team

### 4. Documentation First
- **ALWAYS update relevant docs when making changes**
- Update `README.md` for user-facing features
- Update `PROJECT_STATUS.md` for status changes
- Update `CHANGES.md` for technical changes
- Add/update test documentation

---

## Development Workflow (Individual)

```bash
# 0. Sync with main first (CRITICAL for teams)
git checkout main
git pull origin main

# 1. Create feature branch from latest main
git checkout -b feature/your-feature

# 2. Write failing tests first
flutter test test/feature/your_feature_test.dart  # Should fail

# 3. Implement feature
# ... write code ...

# 4. Run tests
flutter test  # Must pass

# 5. Run static analysis
flutter analyze  # No issues allowed

# 6. Format code
dart format .

# 7. Commit
git add .
git commit -m "feat: Add your feature with tests"

# 8. Sync with main before push (prevents conflicts)
git fetch origin
git rebase origin/main

# 9. Push
git push origin feature/your-feature

# 10. Create PR on GitHub
# - Title: Clear description (use conventional commits)
# - Body: What, why, how
# - Link any issues
# - Ensure CI passes
# - Request review from teammates
```

---

## Collaborative Development

Working with others requires extra care to avoid conflicts and ensure smooth collaboration.

### Before Starting Work

```bash
# 1. Always start with latest main branch
git checkout main
git pull origin main

# 2. Create your feature branch from latest main
git checkout -b feature/your-feature-name

# Branch naming conventions:
# - feature/description       # New feature
# - fix/description          # Bug fix
# - refactor/description      # Code refactoring
# - docs/description         # Documentation only
# - test/description        # Test improvements
# - hotfix/description       # Urgent production fix
```

### Keeping Your Branch Updated

**Sync frequently with main** to avoid merge conflicts:

```bash
# Before every push, sync with main
git checkout main
git pull origin main

# Go back to your feature branch
git checkout feature/your-feature

# Rebase your changes onto latest main
git rebase main

# If there are conflicts, resolve them:
# 1. Open conflicted files and resolve conflicts
# 2. git add <resolved-files>
# 3. git rebase --continue
# (Repeat if more conflicts)

# After successful rebase, force push to update your PR
git push origin feature/your-feature --force-with-lease
# Note: Use --force-with-lease, not -f (safer)
```

### Sync Workflow Summary

```bash
# Daily sync routine (before working):
git checkout main
git pull origin main
git checkout feature/your-feature
git rebase main

# Before pushing (always sync first):
git checkout main
git pull origin main
git checkout feature/your-feature
git rebase main
# Resolve conflicts if any
git push origin feature/your-feature --force-with-lease
```

### Handling Merge Conflicts

When rebase conflicts occur:

```bash
# 1. Git will pause and show conflicts
git status  # Shows conflicted files

# 2. Open each conflicted file and look for:
<<<<<<< HEAD
# Changes from main branch
=======
# Your changes
>>>>>>> feature/your-feature

# 3. Resolve by keeping desired code and removing markers

# 4. Mark as resolved
git add <resolved-file>

# 5. Continue rebase
git rebase --continue

# 6. If multiple conflicts, repeat steps 2-5

# 7. If you want to abort (rarely needed)
git rebase --abort
```

### Pull Request Process

1. **Create Draft PR Early**
   - Create PR as draft once you have basic implementation
   - Get early feedback before finishing
   - Mark as "Ready for review" when done

2. **PR Description Template**
   ```markdown
   ## What
   Brief description of changes

   ## Why
   Reason for this change

   ## How
   Technical approach

   ## Testing
   - [ ] Unit tests pass
   - [ ] Integration tests pass
   - [ ] Manual testing completed

   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Self-review completed
   - [ ] Comments added for complex code
   - [ ] Documentation updated
   - [ ] No new warnings

   ## Related Issues
   Closes #123
   ```

3. **Request Review**
   - Request review from 1-2 teammates
   - Be specific if you need help with certain parts
   - Respond to review comments promptly

4. **Addressing Review Feedback**
   - Make changes on your branch
   - Push changes (they update the PR automatically)
   - Comment with "@reviewer" when ready for re-review

5. **Merging**
   - Do NOT merge your own PR unless agreed
   - Let a teammate approve and merge after reviews pass
   - Ensure CI is green before merge

### Team Best Practices

#### Communication
- **Update the team** on your work in daily standup or chat
- **Tag teammates** in PRs when you need their review
- **Ask questions early** rather than getting stuck
- **Be responsive** to review requests on others' PRs

#### Code Quality
- **Keep PRs small** - easier to review
- **One PR, one feature** - don't mix unrelated changes
- **Clean up** - remove debug code, comments, unused imports
- **Self-review** - review your own code before requesting review

#### Sync Discipline
- **Sync daily** with main branch
- **Rebase before push** to keep history clean
- **Resolve conflicts early** - don't let them accumulate
- **Don't let branches age** - merge or delete within a week

### GitHub Commands

```bash
# List all branches (local and remote)
git branch -a

# See which branch you're on and commits ahead/behind
git status

# See difference between your branch and main
git diff main

# See what commits you're about to push
git log origin/main..HEAD

# Delete local branch after merge
git branch -d feature/your-feature

# Delete remote branch after merge
git push origin --delete feature/your-feature
```

### Conflict Prevention Tips

1. **Work in different areas** of the codebase when possible
2. **Coordinate with teammates** who work on similar files
3. **Sync frequently** - don't wait days between syncs
4. **Keep branches short-lived** - days, not weeks
5. **Communicate** about large refactors or shared files

### GitHub CLI (gh)

The `gh` CLI tool makes GitHub collaboration easier. Install it from https://cli.github.com/

```bash
# Pull Requests
gh pr create                     # Create PR from current branch
gh pr create --title "Fix bug" --body "Description"  # With details
gh pr list                       # List open PRs
gh pr view                       # View current PR
gh pr checkout <number>           # Checkout PR locally to test
gh pr diff                       # Show PR diff
gh pr status                     # Show PR status (checks, reviews)
gh pr review                      # Add review comment

# Issues
gh issue create                   # Create new issue
gh issue list                    # List issues
gh issue view <number>            # View issue details
gh issue close <number>           # Close issue

# Workflows & CI
gh run list                      # List workflow runs
gh run view <run-id>             # View run details
gh run watch <run-id>            # Watch run live
gh run rerun <run-id>            # Rerun failed workflow

# Repos & Sync
gh repo sync                     # Sync fork with upstream
gh repo clone <repo>             # Clone repo with gh auth
gh repo view                      # View repo info

# Notifications
gh notification list              # List notifications
gh notification status           # Show notification count

# Common Patterns
gh pr create --web               # Create PR in browser (for complex ones)
gh pr merge --delete-branch     # Merge and delete branch
gh issue create --label "bug"   # Create bug issue
gh run view --log               # View workflow logs
```

### Troubleshooting

#### "Rebase failed - fix conflicts"
```bash
# Resolve conflicts
git add .
git rebase --continue

# If stuck and want to start over
git rebase --abort
git pull origin main  # Get fresh start
```

#### "Remote contains work you do not have"
```bash
# Someone pushed to main while you're working
git checkout main
git pull origin main
git checkout feature/your-feature
git rebase main
```

#### "PR is outdated"
```bash
# Your branch is behind main - sync it
git checkout main
git pull origin main
git checkout feature/your-feature
git rebase main
git push origin feature/your-feature --force-with-lease
```

---

## Project Structure

```
lib/
├── main.dart                          # Entry point + providers
├── models/
│   └── ssh_connection.dart           # Connection model (ID handling is important!)
├── services/
│   ├── connection_service.dart        # Data persistence + secure storage
│   └── sftp_service.dart              # SFTP operations (18 tests)
├── screens/
│   ├── home_screen.dart               # Connection list
│   ├── add_connection_screen.dart     # Add/edit form + file picker
│   ├── terminal_screen.dart          # Terminal + SSH client (xterm emulator)
│   ├── file_explorer_screen.dart      # SFTP file browser
│   └── file_viewer_screen.dart        # Text and image viewer
└── utils/
    └── ansi_formatter.dart           # ANSI code utilities

test/
├── widget_test.dart                   # Widget tests
└── services/
    └── sftp_service_test.dart         # SFTP service tests (18 tests)
```

---

## Key Technical Details

### SSH Connection (dartssh2)
- Uses `SSHClient` for connections
- Supports password and private key auth
- Uses `SSHSession` with PTY for terminal
- Streams output in real-time

### SFTP Implementation
- `SFTPService` wraps dartssh2 SFTP client
- `RemoteFile` model for file/directory representation
- Operations: list, navigate, upload, download, delete, rename, mkdir
- See `SFTP_MVP_SUMMARY.md` for detailed API notes

### ID Handling (IMPORTANT!)
- Connection IDs are UUIDs generated by `uuid` package
- When editing connections, preserve the original ID
- When creating new connections, generate new UUID
- See `lib/screens/add_connection_screen.dart` for proper handling

### Terminal Emulation
- Uses `xterm` package for VT100/VT220 emulation
- ANSI codes properly handled via `ansi_formatter.dart`
- Real-time streaming via `StreamSubscription`

### Secure Storage
- `flutter_secure_storage` for passwords
- Android Keystore on Android
- KeyChain on iOS (if implemented)
- Private keys kept in memory only (not persisted to storage)

---

## Testing Guidelines

### Unit Tests
- Test business logic, services, models
- Mock dependencies using `mocktail`
- Test success and error paths
- `test/services/sftp_service_test.dart` is a good example

### Widget Tests
- Test UI components in isolation
- Test user interactions
- Test state changes

### Integration Tests
- For critical user flows and end-to-end scenarios
- Two approaches available:
  1. **App Flow Tests** - No Docker required, test UI navigation
  2. **SSH Connection Tests** - Full end-to-end with Docker SSH server
- Run with: `flutter test integration_test/`
- See `INTEGRATION_TESTS.md` for full documentation
- Screenshots captured automatically at each step
- Use `./scripts/run-app-flow-tests.sh` for quick app flow tests
- Use `./scripts/run-integration-tests.sh` for full SSH tests (requires Docker)

### Test Coverage Goal
- Aim for 80%+ coverage on services
- Critical paths must have 100% coverage
- Integration tests cover user journey through the app

---

## CI/CD

### GitHub Actions
- `.github/workflows/build.yml` runs on every PR and push to main
- **On PR:**
  - Builds project
  - Runs all unit and widget tests
  - Runs static analysis (`flutter analyze`)
  - Must pass before PR can merge
- **On main branch push:**
  - Runs all tests
  - Can trigger deployment (when configured)

### CI/CD Best Practices for Teams

#### Before Pushing to PR
```bash
# Run locally what CI runs
flutter test              # All tests must pass
flutter analyze          # No issues allowed
dart format .            # Code formatted
```

#### CI Failure Actions
- **Don't merge** if CI fails
- **Fix locally** and push to your branch
- CI automatically re-runs on new commits
- **Check CI logs** if unclear why it failed

#### Troubleshooting CI Failures
```bash
# Pull CI environment locally
flutter pub get
flutter test  # Should reproduce CI failures
flutter analyze  # Should show same issues

# Check Flutter version matches CI
flutter --version  # Should match .github/workflows/build.yml
```

### Build Commands
```bash
# Development builds
flutter run                     # Run in debug
flutter run --release           # Run in release mode

# Production builds
flutter build apk --release     # Release APK
flutter build appbundle --release  # Play Store bundle

# Testing
flutter test                    # Run all tests
flutter test --coverage         # With coverage
flutter test integration_test/  # Integration tests

# Code quality
flutter analyze                 # Static analysis
dart format .                   # Format code
flutter pub get                 # Get dependencies
flutter pub outdated            # Check for updates
```

---

## Common Patterns

### Service Pattern
```dart
class ExampleService {
  Future<Result> doSomething() async {
    try {
      // Do work
      return Success(...);
    } catch (e) {
      return Failure(e.toString());
    }
  }
}
```

### Screen Pattern with Provider
```dart
class ExampleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ExampleService>(
      builder: (context, service, child) {
        return Scaffold(...);
      },
    );
  }
}
```

### Resource Cleanup Pattern
```dart
@override
void dispose() {
  _client?.close();
  _session?.close();
  _outputSubscription?.cancel();
  super.dispose();
}
```

---

## Code Quality Standards

### Static Analysis
- `flutter analyze` must produce no issues
- Use `analysis_options.yaml` for configuration
- `flutter_lints: ^6.0.0` package

### Formatting
- Use `dart format .` for consistent formatting
- Follow Dart style guide

### Naming
- Classes: PascalCase (e.g., `SFTPService`)
- Functions/Variables: camelCase (e.g., `connectToServer`)
- Constants: lowerCamelCase or UPPER_SNAKE_CASE for constants
- Private members: prefix with `_`

### Error Handling
- Always use try-catch for async operations
- Provide user-friendly error messages
- Log technical errors for debugging

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter | sdk | UI framework |
| dartssh2 | ^2.8.6 | SSH client |
| flutter_secure_storage | ^9.2.2 | Secure credential storage |
| provider | ^6.1.2 | State management |
| xterm | ^4.0.0 | Terminal emulator |
| file_picker | ^8.1.6 | File selection |
| path_provider | ^2.1.4 | File paths |
| uuid | ^4.5.1 | Unique IDs |
| shared_preferences | ^2.3.3 | Connection metadata |
| mocktail | ^1.0.4 | Test mocking |

---

## Quick Reference Commands

```bash
# Flutter
flutter test                    # Run all tests (unit + widget)
flutter test --coverage         # With coverage
flutter analyze                 # Static analysis
dart format .                   # Format code
flutter pub get                 # Get dependencies
flutter pub outdated            # Check for updates

# Integration Tests
flutter test integration_test/  # Run all integration tests
flutter test integration_test/app_flow_test.dart  # App flow only (no Docker)
flutter test integration_test/ssh_connection_test.dart  # Full SSH tests (needs Docker)
./scripts/run-app-flow-tests.sh  # Run app flow tests with prompts
./scripts/run-integration-tests.sh  # Full automation (starts Docker, runs tests)

# Docker SSH Test Server
docker compose -f docker-compose.test.yml up -d  # Start SSH server
docker compose -f docker-compose.test.yml down  # Stop SSH server
./docker/test-ssh-server.sh start  # Start via script
./docker/test-ssh-server.sh stop   # Stop via script
./docker/test-ssh-server.sh status # Check status

# Git
git checkout -b feature/name     # Create feature branch
git checkout main               # Switch to main
git merge feature/name          # Merge feature
git push origin feature/name    # Push branch

# Git Sync & Rebase (Team Collaboration)
git checkout main               # Switch to main
git pull origin main            # Update local main from remote
git checkout feature/name       # Back to feature branch
git rebase main                # Rebase feature on latest main
git push origin feature/name --force-with-lease  # Push updated branch
git fetch origin               # Update remote tracking info
git log origin/main..HEAD      # See commits you're about to push

# GitHub PR & Issues (requires gh CLI)
gh pr create                   # Create PR for current branch
gh pr list                     # List open PRs
gh pr view                     # View current branch's PR
gh pr checkout <number>         # Checkout PR locally
gh pr merge                    # Merge PR (after approval)
gh pr close                    # Close PR
gh issue create                 # Create new issue
gh issue list                  # List issues

# Build
flutter run                     # Run in debug
flutter build apk --release     # Build APK
flutter build appbundle --release  # Build AAB

# SSH/Terminal Testing (manual)
# Connect to localhost or test server
# Test password and key auth
# Test terminal commands
# Test SFTP operations
```

---

## Known Issues & Gotchas

### dartssh2 API Differences
- `listdir()` not `listDir()`
- `SftpName` returned, not `SftpFile`
- Check `attr.mode?.type` for directory detection
- Use `attr.size`, `attr.modifyTime` for metadata

### File Upload Testing
- Mocking `file.write(Stream)` is complex
- Upload test is skipped - use integration tests instead

### Terminal ANSI Codes
- Complex apps may still have display issues
- xterm emulator handles most cases
- See `ansi_formatter.dart` for utilities

---

## When to Ask for Help

- Unclear about feature requirements
- Unsure about test coverage
- API design questions
- Performance concerns
- Security questions
- Architecture decisions

---

## Future Work Priority

### High Priority
- Host key verification
- Device filesystem integration for downloads
- Progress indicators for transfers

### Medium Priority
- Multiple file selection
- Terminal font size adjustment
- Copy/paste from terminal

### Low Priority
- SSH tunneling
- Port forwarding
- X11 forwarding
- Background transfers

---

**Last Updated:** 2026-02-25
**Project Status:** Production Ready ✅
**Integration Tests:** Added ✅
