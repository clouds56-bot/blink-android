# AGENTS.md - blink-android

Project conventions and workflows for AI assistants working on this Flutter app.

## Core Principles

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

## Development Workflow

```bash
# 1. Create feature branch
git checkout -b feature/your-feature

# 2. Write failing tests first
flutter test lib/feature/your_feature_test.dart  # Should fail

# 3. Implement feature
# ... write code ...

# 4. Run tests
flutter test  # Must pass

# 5. Commit and push
git add .
git commit -m "Add your feature with tests"
git push origin feature/your-feature

# 6. Create PR on GitHub
# - Title: Clear description
# - Body: What, why, how
# - Link any issues
```

## Project Structure

```
lib/
├── main.dart
├── models/
├── screens/
├── services/
└── widgets/

test/
├── models/
├── screens/
├── services/
└── widgets/
```

## Testing Guidelines

- **Unit tests** for business logic, services, models
- **Widget tests** for UI components
- **Integration tests** for critical user flows

## CI/CD

- GitHub Actions builds and tests on every PR
- PR cannot be merged if CI fails
- Build workflow: `.github/workflows/build.yml`

## Quick Commands

```bash
flutter test                    # Run all tests
flutter test --coverage         # Run with coverage
flutter analyze                 # Static analysis
flutter pub get                 # Get dependencies
flutter build apk --release     # Build release APK
```

## Important Notes

- This is a Flutter SSH client app
- Uses `dartssh2` for SSH connections
- Passwords stored securely (see `connectionService`)
- ID handling matters - check recent fixes in `lib/screens/add_connection_screen.dart`
