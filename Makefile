.PHONY: test lint check install-hooks uninstall-hooks clean help

# Run all tests
test:
	@./tests/run_tests.sh

# Run specific test file (e.g., make test-ui runs test_ui.sh)
test-%:
	@./tests/run_tests.sh test_$*.sh

# Lint all scripts with shellcheck
lint:
	@shellcheck --severity=error funny_gums.sh lib/**/*.sh examples/*.sh tests/*.sh

# Run both lint and tests (mirrors CI)
check: lint test

# Install git pre-commit hook (no Python required)
install-hooks:
	@cp scripts/pre-commit .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "Pre-commit hook installed"

# Remove git hooks
uninstall-hooks:
	@rm -f .git/hooks/pre-commit
	@echo "Pre-commit hook removed"

# Clean generated files
clean:
	@rm -f tests/*.log
	@echo "Cleaned"

# Help
help:
	@echo "Available targets:"
	@echo "  make check           - Run lint + tests (mirrors CI)"
	@echo "  make test            - Run all tests"
	@echo "  make test-ui         - Run specific test (e.g., test_ui.sh)"
	@echo "  make lint            - Run shellcheck"
	@echo "  make install-hooks   - Install git pre-commit hook"
	@echo "  make uninstall-hooks - Remove git pre-commit hook"
	@echo "  make clean           - Clean generated files"
