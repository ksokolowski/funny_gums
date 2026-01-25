.PHONY: test lint check install-hooks clean

# Run all tests
test:
	@./tests/run_tests.sh

# Run specific test file
test-%:
	@./tests/run_tests.sh test_$*.sh

# Lint all scripts with shellcheck
lint:
	@shellcheck --severity=error funny_gums.sh lib/**/*.sh examples/*.sh tests/*.sh

# Run both lint and tests (mirrors CI)
check: lint test

# Install pre-commit hooks
install-hooks:
	@command -v pre-commit >/dev/null 2>&1 || { echo "Install pre-commit: pip install pre-commit"; exit 1; }
	@pre-commit install
	@echo "Pre-commit hooks installed"

# Clean generated files
clean:
	@rm -f tests/*.log
	@echo "Cleaned"

# Help
help:
	@echo "Available targets:"
	@echo "  make test          - Run all tests"
	@echo "  make test-ui       - Run specific test (e.g., test_ui.sh)"
	@echo "  make lint          - Run shellcheck"
	@echo "  make check         - Run lint + tests (mirrors CI)"
	@echo "  make install-hooks - Install pre-commit hooks"
	@echo "  make clean         - Clean generated files"
