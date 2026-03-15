.PHONY: help setup deps test lint check format format-check clean

# Help (Default Target)
help:
	@echo "Available targets:"
	@echo "  make setup           - Configure dev environment (git hooks, deps)"
	@echo "  make deps            - Check project dependencies"
	@echo "  make check           - Run lint + format-check + tests (mirrors CI)"
	@echo "  make test            - Run all tests"
	@echo "  make test-ui         - Run specific test (e.g., test_ui.sh)"
	@echo "  make lint            - Run shellcheck"
	@echo "  make format          - Auto-format all scripts with shfmt"
	@echo "  make format-check    - Check script formatting without applying"
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
	@find lib -name '*.sh' -print0 | xargs -0 shellcheck --severity=error funny_gums.sh examples/*.sh tests/*.sh

# Run both lint and tests (mirrors CI)
check: lint format-check test

# Auto-format all scripts with shfmt (4 spaces, binary operators start lines)
format:
	@shfmt -i 4 -w .

# Check script formatting without applying changes
format-check:
	@shfmt -i 4 -d .

# Clean generated files
clean:
	@rm -f tests/*.log /tmp/test_gum_log_*.log /tmp/test_runner_*.log
	@echo "Cleaned"
