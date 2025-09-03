.PHONY: run lint fmt fmt-check test test-docker hooks-install ci

run:
	@bash typing.sh

lint:
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck typing.sh; \
	else \
		echo "shellcheck が見つかりません。インストールしてください。"; \
	fi

fmt:
	@if command -v shfmt >/dev/null 2>&1; then \
		shfmt -i 2 -ci -w typing.sh; \
	else \
		echo "shfmt が見つかりません。インストールしてください。"; \
	fi

fmt-check:
	@if command -v shfmt >/dev/null 2>&1; then \
		shfmt -i 2 -ci -d typing.sh; \
	else \
		echo "shfmt が見つかりません。インストールしてください。"; \
	fi

test:
	@if command -v bats >/dev/null 2>&1; then \
		if [ -d tests ]; then \
			bats tests; \
		else \
			echo "tests ディレクトリがありません。"; \
		fi; \
	else \
		echo "bats が見つかりません。インストールしてください。"; \
	fi

# Docker 上で Bats を実行
test-docker:
	@./scripts/test-docker.sh -r tests

# Git フックを hooks/ に設定
hooks-install:
	@bash scripts/install-hooks.sh

# CI まとめ実行（lint, fmt-check, test-docker）
ci:
	@$(MAKE) lint
	@$(MAKE) test-docker
