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
    if rg -n -- '^\s*--ctp-[a-z0-9]+\s*:\s*#' src --glob '!src/flavors/**'; then
        echo "error: palette variables may only be defined in src/flavors/" >&2
        exit 1
    fi
    if rg -n '#[0-9a-fA-F]{3,8}\b' src --glob '!src/flavors/**' --glob '!src/core/tokens.css'; then
        echo "error: hardcoded colors outside src/flavors/ and src/core/tokens.css" >&2
        exit 1
    fi
    echo "ok"
