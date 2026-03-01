root = $(shell git rev-parse --show-toplevel)
SYSTEM := $(shell nix eval --impure --raw --expr 'builtins.currentSystem')
LINUX := x86_64-linux
DARWIN := aarch64-darwin

.PHONY: fmt
fmt:
	treefmt

update-sub-flake:
	cd $(root)
	cd src/local && nix flake update
	cd src/tests && nix flake update

ci-local: ci-checks ci-cli ci-shells ci-format
	@echo "=== All CI checks passed ==="

ci-all: ci-checks-all ci-cli-all ci-shells-all ci-format
	@echo "=== All CI checks passed (all systems) ==="

# Not in ci-local by default: dirties flake.lock files, requires committed HEAD.
# Add to ci-local prereqs if full CI parity needed.
ci-sync:
	@echo "=== Syncing subflake locks ==="
	./.github/workflows/update-subflake.sh

ci-checks:
	@echo "=== Running checks ==="
	nix build .#checks.$(SYSTEM) --no-link

ci-checks-all: ci-checks-linux ci-checks-darwin
ci-checks-linux:
	@echo "=== Running checks (linux) ==="
	nix build .#checks.$(LINUX) --no-link
ci-checks-darwin:
	@echo "=== Running checks (darwin) ==="
	nix build .#checks.$(DARWIN) --no-link

ci-cli:
	@echo "=== Building CLI ==="
	nix build .#packages.$(SYSTEM).default

ci-cli-all: ci-cli-linux ci-cli-darwin
ci-cli-linux:
	@echo "=== Building CLI (linux) ==="
	nix build .#packages.$(LINUX).default
ci-cli-darwin:
	@echo "=== Building CLI (darwin) ==="
	nix build .#packages.$(DARWIN).default

ci-shells:
	@echo "=== Building devshells ==="
	nix build .#devShells.$(SYSTEM).default --no-link

ci-shells-all: ci-shells-linux ci-shells-darwin
ci-shells-linux:
	@echo "=== Building devshells (linux) ==="
	nix build .#devShells.$(LINUX).default --no-link
ci-shells-darwin:
	@echo "=== Building devshells (darwin) ==="
	nix build .#devShells.$(DARWIN).default --no-link

ci-format:
	@echo "=== Checking formatting ==="
	treefmt --fail-on-change

.PHONY: update-sub-flake ci-local ci-all ci-sync
.PHONY: ci-checks ci-checks-all ci-checks-linux ci-checks-darwin
.PHONY: ci-cli ci-cli-all ci-cli-linux ci-cli-darwin
.PHONY: ci-shells ci-shells-all ci-shells-linux ci-shells-darwin
.PHONY: ci-format
