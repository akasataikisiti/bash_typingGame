.PHONY: run lint fmt fmt-check test

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

