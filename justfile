_default:
    @just --list

# Regenerate flavor and accent CSS from the Catppuccin palette.
build:
    whiskers templates/flavors.tera
    whiskers templates/accents.tera

# Fail if any file outside src/flavors|src/accents defines a palette variable,
# or hardcodes a color outside the documented fallbacks in src/core/tokens.css.
check:
    #!/usr/bin/env bash
    set -euo pipefail
    if rg -n --glob '!src/flavors/**' -- '^\s*--ctp-[a-z0-9]+\s*:\s*#' src; then
        echo "error: palette variables may only be defined in src/flavors/" >&2
        exit 1
    fi
    # Comments are stripped first: rules that target a generated class are
    # required to record the color they replace, so hex inside a comment is
    # the convention, not a violation.
    fail=0
    for f in $(rg --files src --glob '!src/flavors/**' --glob '!src/core/tokens.css'); do
        if perl -0777 -pe 's{/\*.*?\*/}{}gs' "$f" | rg -n '#[0-9a-fA-F]{3,8}\b' --with-filename --heading -; then
            echo "  ^ in $f" >&2
            fail=1
        fi
    done
    if [ "$fail" -ne 0 ]; then
        echo "error: hardcoded colors outside src/flavors/ and src/core/tokens.css" >&2
        exit 1
    fi
    echo "ok"
