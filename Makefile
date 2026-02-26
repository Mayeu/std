root = $(shell git rev-parse --show-toplevel)
SYSTEM := $(shell nix eval --impure --raw --expr 'builtins.currentSystem')

update-sub-flake:
	cd $(root)
	cd src/local && nix flake update
	cd src/tests && nix flake update

ci-local: ci-checks ci-cli ci-shells ci-format
	@echo "=== All CI checks passed ==="

# Not in ci-local by default: dirties flake.lock files, requires committed HEAD.
# Add to ci-local prereqs if full CI parity needed.
ci-sync:
	@echo "=== Syncing subflake locks ==="
	./.github/workflows/update-subflake.sh

ci-checks:
	@echo "=== Running checks ==="
	nix flake check

ci-cli:
	@echo "=== Building CLI ==="
	nix build .#packages.$(SYSTEM).default

ci-shells:
	@echo "=== Building devshells ==="
	nix build .#devShells.$(SYSTEM).default --no-link

ci-format:
	@echo "=== Checking formatting ==="
	treefmt --fail-on-change

.PHONY: update-sub-flake ci-local ci-sync ci-checks ci-cli ci-shells ci-format
