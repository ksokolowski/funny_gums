.PHONY: help setup deps test lint check clean

# Help (Default Target)
help:
	@echo "Available targets:"
	@echo "  make setup           - Configure dev environment (git hooks, deps)"
	@echo "  make deps            - Check project dependencies"
	@echo "  make check           - Run lint + tests (mirrors CI)"
	@echo "  make test            - Run all tests"
	@echo "  make test-ui         - Run specific test (e.g., test_ui.sh)"
	@echo "  make lint            - Run shellcheck"
	@echo "  make clean           - Clean generated files"

# Setup development environment
setup:
	@git config core.hooksPath scripts
	@chmod +x scripts/pre-commit
	@./scripts/check_deps.sh
	@echo "Development environment configured."

# Check dependencies
deps:
	@./scripts/check_deps.sh

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

# Clean generated files
clean:
	@rm -f tests/*.log
	@echo "Cleaned"
