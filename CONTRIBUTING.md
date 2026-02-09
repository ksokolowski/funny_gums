# Contributing to Funny Gums

Thank you for your interest in contributing to Funny Gums! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and constructive
- Focus on what is best for the community
- Show empathy towards other community members

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the issue
- **Expected vs actual behavior**
- **Environment details**: OS, Bash version, terminal emulator
- **Relevant logs or error messages**

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear use case** for the feature
- **Expected behavior** and API design
- **Examples** of how it would be used

### Pull Requests

1. **Fork the repository** and create your branch from `master`
2. **Follow the coding conventions** (see below)
3. **Add tests** for new functionality
4. **Update documentation** as needed
5. **Run quality checks**: `make check`
6. **Commit with clear messages** following [Conventional Commits](https://www.conventionalcommits.org/)

## Development Workflow

### Setup

```bash
git clone https://github.com/ksokolowski/funny_gums.git
cd funny_gums
make setup  # Install git hooks
make deps   # Verify dependencies
```

### Testing

```bash
make test              # Run all tests
make test-ui           # Run specific test file
make lint              # Run shellcheck
make check             # Full verification (lint + tests)
```

### Pre-commit Hooks

The project uses native git hooks (no Python required):

```bash
make setup             # Install hooks (runs automatically)
```

Hooks run `shellcheck` and tests on every commit. Always run `make check` before pushing.

## Coding Conventions

### Shell Style

- **Shebang**: `#!/usr/bin/env bash`
- **Strict mode**: `set -uo pipefail` (omit `-e` in tests)
- **Quote variables**: Always use `"$var"`
- **Guard pattern**: Prevent multiple sourcing
  ```bash
  [[ -n "${_MODULE_SH_LOADED:-}" ]] && return 0
  _MODULE_SH_LOADED=1
  ```

### Naming

- **Functions**: `namespace_action` (e.g., `ui_box`, `log_info`)
- **Globals**: `UPPER_SNAKE_CASE`
- **Internal**: `_namespace_helper` (leading underscore)

### Emoji Usage

**Never hardcode emojis.** Use constants from `lib/core/text/emojis.sh`:

```bash
# ❌ Wrong
echo "✅ Success"

# ✅ Correct
echo "${EMOJI_SUCCESS} Success"
```

This ensures automatic fallback for terminals lacking VS16/ZWJ support.

### Documentation

- **File headers**: Brief description of module purpose
- **Function documentation**: Usage examples and parameter descriptions
- **Inline comments**: Explain complex logic, not obvious code

### Testing

- Use the test framework in `tests/framework.sh`
- Test file naming: `test_<module>.sh`
- Assertions: `assert_eq`, `assert_success`, `assert_fails`, `assert_function_exists`

Example:
```bash
test_file_start "ui.sh"
source "$PROJECT_DIR/lib/ui/layout/ui.sh"

assert_function_exists "ui_box"
assert_success ui_box "Test" "Content"
```

## Shellcheck Compliance

All scripts must pass `shellcheck --severity=error`. Common directives:

```bash
# shellcheck disable=SC2034  # Unused variable (if intentional)
# shellcheck disable=SC1091  # Can't follow source
```

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

**Examples**:
```
feat(ui): add ui_progress_bar widget
fix(emoji): correct VS16 width calculation for iTerm
docs: update installation instructions for Fedora
test: add coverage for gpu module
```

## Module Structure

New modules should follow this pattern:

```bash
#!/usr/bin/env bash
# module_name.sh - Brief description
# shellcheck disable=SC2034

[[ -n "${_MODULE_NAME_LOADED:-}" ]] && return 0
_MODULE_NAME_LOADED=1

# Get script directory
_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source dependencies
source "$_DIR/dependency.sh"

# Public function
# Usage: module_action "arg"
module_action() {
    local arg="$1"
    # Implementation
}
```

## Questions?

- Open an issue for questions about contributing
- Check existing issues and documentation
- Be patient - maintainers are volunteers

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
