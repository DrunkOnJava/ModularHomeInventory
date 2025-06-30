# Contributing to Home Inventory

Thank you for your interest in contributing to Home Inventory! This guide will help you get started with our development workflow and standards.

## Getting Started

### Prerequisites

1. **Xcode 15.0+** - Download from the Mac App Store
2. **Homebrew** - Install from [brew.sh](https://brew.sh)
3. **Ruby 3.2+** - Install via rbenv: `brew install rbenv`

### Setting Up Your Development Environment

```bash
# Clone the repository
git clone https://github.com/yourusername/ModularHomeInventory.git
cd ModularHomeInventory

# Install all development tools
make install-all-tools

# Generate the Xcode project
make generate

# Build and run the app
make build run
```

## Development Workflow

### 1. Before You Start Coding

```bash
# Create a new branch
git checkout -b feature/your-feature-name

# Ensure tools are up to date
bundle install
brew upgrade swiftlint swiftformat periphery
```

### 2. While Coding

#### Code Style
We use **SwiftLint** and **SwiftFormat** to maintain consistent code style:

```bash
# Check your code
make lint

# Auto-fix issues
make lint-fix

# Format code
make format
```

#### Testing
Write tests for new features and ensure existing tests pass:

```bash
# Run all tests
make test

# Run snapshot tests
make test-snapshots

# Record new snapshots (when UI changes)
make record-snapshots
```

### 3. Before Committing

Our pre-commit hooks will automatically:
- Run SwiftLint
- Format code with SwiftFormat
- Check for TODOs/FIXMEs
- Validate project configuration

You can also run these manually:

```bash
make pre-commit
```

### 4. Before Creating a Pull Request

Run comprehensive checks:

```bash
# Run all pre-merge checks
make pre-merge

# Check for dead code
make dead-code

# Generate documentation
make docs
```

## Code Standards

### Swift Style Guide

We follow the [Ray Wenderlich Swift Style Guide](https://github.com/raywenderlich/swift-style-guide) with some modifications defined in `.swiftlint.yml`.

Key points:
- Use 4 spaces for indentation
- Maximum line length: 120 characters
- Use descriptive variable and function names
- Add documentation comments for public APIs

### Project Structure

```
Modules/
├── Core/           # Core models and services
├── SharedUI/       # Reusable UI components
├── Items/          # Item management feature
├── BarcodeScanner/ # Barcode scanning feature
└── ...             # Other feature modules
```

Each module should:
- Have its own `Package.swift`
- Include unit tests
- Follow single responsibility principle
- Minimize dependencies on other modules

### Commit Messages

Follow conventional commit format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test changes
- `chore`: Build/tool changes

Example:
```
feat(items): Add barcode scanning support

- Integrated AVFoundation for camera access
- Added barcode detection and parsing
- Created UI for scanner overlay

Closes #123
```

## Pull Request Process

1. **Create a PR** with a clear title and description
2. **Fill out the PR template** completely
3. **Ensure CI passes** - All GitHub Actions must be green
4. **Address review feedback** promptly
5. **Keep PR focused** - One feature/fix per PR

### PR Checklist

- [ ] Tests pass locally (`make test`)
- [ ] Code is linted (`make lint`)
- [ ] Documentation updated if needed
- [ ] No dead code introduced (`make dead-code`)
- [ ] PR description explains the changes
- [ ] Screenshots included for UI changes

## Tools and Commands Reference

### Essential Make Commands

```bash
# Building
make build          # Build for iPhone
make build-ipad     # Build for iPad
make run            # Run in simulator

# Testing
make test           # Run all tests
make test-snapshots # Run snapshot tests

# Code Quality
make lint           # Check code style
make format         # Format code
make analyze        # Static analysis
make dead-code      # Find unused code

# Documentation
make docs           # Generate docs
make docs-open      # Open docs in browser

# Deployment
make testflight     # Upload to TestFlight
make archive        # Create archive
```

### Tool Configuration Files

- `.swiftlint.yml` - SwiftLint rules
- `.swiftformat` - Code formatting rules
- `.periphery.yml` - Dead code detection
- `.sourcery.yml` - Code generation
- `Dangerfile.swift` - PR automation
- `project.yml` - XcodeGen configuration

## Automated Checks

### Pre-commit Hooks
Automatically run on every commit:
1. SwiftLint validation
2. SwiftFormat checking
3. TODO/FIXME detection
4. Print statement detection

### CI/CD (GitHub Actions)
On every push:
1. Build validation
2. Test execution
3. Snapshot testing
4. Code coverage reporting

On PRs:
1. Danger automated review
2. SwiftLint inline comments
3. PR size warnings
4. Test coverage requirements

## Getting Help

- Check [TOOLS_GUIDE.md](TOOLS_GUIDE.md) for detailed tool documentation
- Review existing issues and PRs
- Ask questions in PR comments
- Check `docs/` directory for architecture guides

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Help others learn and grow
- Focus on what's best for the project

Thank you for contributing! 🎉