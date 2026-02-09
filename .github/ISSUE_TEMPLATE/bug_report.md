---
name: Bug Report
about: Report a bug or unexpected behavior
title: '[BUG] '
labels: bug
assignees: ''
---

## Bug Description
A clear and concise description of what the bug is.

## To Reproduce
Steps to reproduce the behavior:
1. Source module '...'
2. Call function '...'
3. Pass arguments '...'
4. See error

## Expected Behavior
A clear and concise description of what you expected to happen.

## Actual Behavior
What actually happened. Include error messages and relevant output.

```bash
# Paste error output here
```

## Environment
- **OS**: [e.g., Ubuntu 24.04, macOS 14.0, Arch Linux]
- **Bash version**: [output of `bash --version`]
- **Terminal**: [e.g., Kitty, GNOME Terminal, iTerm2, VS Code]
- **Gum version**: [output of `gum --version`]
- **Funny Gums**: [commit hash or version]

## Minimal Reproducible Example
```bash
#!/usr/bin/env bash
source ./funny_gums.sh

# Minimal code that reproduces the issue
```

## Additional Context
Add any other context about the problem here (screenshots, related issues, etc.).

## Checklist
- [ ] I have searched existing issues for duplicates
- [ ] I have included environment details
- [ ] I have provided a minimal reproducible example
- [ ] I have run `make check` to rule out local issues
